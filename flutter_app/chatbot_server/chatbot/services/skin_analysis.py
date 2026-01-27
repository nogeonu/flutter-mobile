import numpy as np
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io
import json
import base64
from pathlib import Path
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)

class SkinAnalysisService:
    """피부 질환 분석 서비스 (MobileNetV2 기반, PyTorch)"""
    
    def __init__(self):
        self.model = None
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.class_labels = {}
        self.model_path = Path(__file__).parent.parent.parent / "models" / "mobilenet_skin_disease_finetuned.pth"
        self.labels_path = Path(__file__).parent.parent.parent / "models" / "labels.json"
        self._load_model()
        self._load_labels()
        self._setup_transforms()
    
    def _setup_transforms(self):
        """이미지 전처리 변환 설정"""
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    
    def _load_model(self):
        """PyTorch MobileNetV2 모델 로드"""
        try:
            if self.model_path.exists():
                # MobileNetV2 모델 구조 생성 (학습된 구조와 동일하게)
                model = models.mobilenet_v2(pretrained=False)
                num_features = model.classifier[1].in_features
                
                # 학습된 모델과 동일한 분류기 구조
                model.classifier = nn.Sequential(
                    nn.Dropout(0.5),
                    nn.Linear(num_features, 256),
                    nn.ReLU(),
                    nn.BatchNorm1d(256),
                    nn.Dropout(0.3),
                    nn.Linear(256, 7)
                )
                
                # 모델 로드
                model.load_state_dict(torch.load(str(self.model_path), map_location=self.device))
                model.eval()
                model.to(self.device)
                self.model = model
                logger.info(f"✅ 피부 분석 모델 로드 완료: {self.model_path} (Device: {self.device})")
            else:
                logger.warning(f"⚠️ 모델 파일을 찾을 수 없습니다: {self.model_path}")
                logger.info("기본 MobileNetV2 모델을 생성합니다...")
                self.model = self._create_default_model()
        except Exception as e:
            logger.error(f"❌ 모델 로드 실패: {e}", exc_info=True)
            self.model = self._create_default_model()
    
    def _load_labels(self):
        """라벨 정보 로드"""
        try:
            if self.labels_path.exists():
                with open(self.labels_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.class_labels = {
                        int(k): v for k, v in data.get('classes', {}).items()
                    }
                logger.info(f"✅ 라벨 정보 로드 완료: {len(self.class_labels)}개 클래스")
            else:
                logger.warning(f"⚠️ 라벨 파일을 찾을 수 없습니다: {self.labels_path}")
                self._create_default_labels()
        except Exception as e:
            logger.error(f"❌ 라벨 로드 실패: {e}")
            self._create_default_labels()
    
    def _create_default_labels(self):
        """기본 라벨 생성"""
        self.class_labels = {
            0: {"code": "akiec", "name": "광선각화증"},
            1: {"code": "bcc", "name": "기저세포암"},
            2: {"code": "bkl", "name": "양성각화증"},
            3: {"code": "df", "name": "피부섬유종"},
            4: {"code": "mel", "name": "흑색종"},
            5: {"code": "nv", "name": "멜라닌모반"},
            6: {"code": "vasc", "name": "혈관병변"}
        }
    
    def _create_default_model(self):
        """기본 MobileNetV2 모델 생성 (PyTorch)"""
        model = models.mobilenet_v2(pretrained=True)
        num_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(0.5),
            nn.Linear(num_features, 256),
            nn.ReLU(),
            nn.BatchNorm1d(256),
            nn.Dropout(0.3),
            nn.Linear(256, 7)
        )
        model.eval()
        model.to(self.device)
        logger.warning("⚠️ 기본 MobileNetV2 모델 사용 (학습된 가중치 없음)")
        return model
    
    def preprocess_image(self, image_bytes: bytes) -> torch.Tensor:
        """이미지 전처리 (PyTorch MobileNetV2 입력 형식)"""
        # PIL로 이미지 로드
        image = Image.open(io.BytesIO(image_bytes))
        image = image.convert('RGB')
        
        # 전처리 변환 적용
        image_tensor = self.transform(image)
        
        # 배치 차원 추가
        image_tensor = image_tensor.unsqueeze(0)
        
        return image_tensor.to(self.device)
    
    def predict(self, image_bytes: bytes) -> Dict:
        """이미지 분석 및 예측"""
        try:
            # 이미지 전처리
            processed_image = self.preprocess_image(image_bytes)
            
            # 예측 (PyTorch)
            with torch.no_grad():
                outputs = self.model(processed_image)
                probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
                predicted_class_idx = int(torch.argmax(probabilities))
                confidence = float(probabilities[predicted_class_idx])
            
            # NumPy로 변환
            probs_np = probabilities.cpu().numpy()
            
            # 예측된 클래스 정보
            predicted_label = self.class_labels.get(predicted_class_idx, {
                "code": "unknown",
                "name": "알 수 없음"
            })
            
            # 클래스별 확률
            class_probabilities = {}
            for i in range(len(probs_np)):
                label_info = self.class_labels.get(i, {"code": f"class_{i}", "name": f"클래스 {i}"})
                class_probabilities[label_info['name']] = float(probs_np[i])
            
            # 상위 3개 예측 결과
            top_3_indices = np.argsort(probs_np)[-3:][::-1]
            top_3_predictions = []
            for idx in top_3_indices:
                label_info = self.class_labels.get(int(idx), {"code": f"class_{idx}", "name": f"클래스 {idx}"})
                top_3_predictions.append({
                    "class_name": label_info['name'],
                    "class_code": label_info['code'],
                    "confidence": float(probs_np[idx])
                })
            
            # 히트맵 생성 (선택사항)
            heatmap_base64 = None
            try:
                # 히트맵 생성을 위해 이미지 재전처리 (gradient 계산을 위해)
                heatmap_image = self.preprocess_image(image_bytes)
                heatmap = self.generate_gradcam_heatmap(heatmap_image, predicted_class_idx)
                heatmap_base64 = self.heatmap_to_base64(heatmap, image_bytes)
            except Exception as e:
                logger.warning(f"히트맵 생성 실패: {e}", exc_info=True)
            
            return {
                "status": "success",
                "predicted_class": predicted_label['name'],
                "predicted_code": predicted_label['code'],
                "confidence": confidence,
                "class_probabilities": class_probabilities,
                "top_3_predictions": top_3_predictions,
                "heatmap": heatmap_base64,
                "warning": "⚠️ 이 결과는 참고용입니다. 반드시 피부과 전문의의 진단을 받으세요."
            }
        except Exception as e:
            logger.error(f"예측 실패: {e}", exc_info=True)
            return {
                "status": "error",
                "message": f"분석 중 오류가 발생했습니다: {str(e)}"
            }
    
    def generate_gradcam_heatmap(self, image_tensor: torch.Tensor, predicted_class: int) -> np.ndarray:
        """Grad-CAM 기반 히트맵 생성"""
        try:
            # 모델을 학습 모드로 전환 (gradient 계산을 위해)
            self.model.train()
            
            # 입력 이미지에 gradient 계산 활성화
            image_tensor.requires_grad_(True)
            
            # MobileNetV2의 마지막 컨볼루션 레이어 활성화 가져오기
            # features 레이어의 마지막 블록 사용
            activations = []
            gradients = []
            
            def forward_hook(module, input, output):
                activations.append(output)
            
            def backward_hook(module, grad_input, grad_output):
                gradients.append(grad_output[0])
            
            # MobileNetV2의 마지막 컨볼루션 레이어에 hook 등록
            # features[-1]이 마지막 InvertedResidual 블록
            handle_forward = self.model.features[-1].register_forward_hook(forward_hook)
            handle_backward = self.model.features[-1].register_backward_hook(backward_hook)
            
            try:
                # Forward pass
                output = self.model(image_tensor)
                
                # 예측된 클래스에 대한 gradient 계산
                self.model.zero_grad()
                output[0][predicted_class].backward(retain_graph=True)
                
                # Gradient와 활성화 가져오기
                if len(gradients) > 0 and len(activations) > 0:
                    grad = gradients[0]
                    act = activations[0]
                    
                    # Gradient의 평균 계산 (채널별)
                    weights = torch.mean(grad, dim=(2, 3), keepdim=True)
                    
                    # 가중치를 적용한 활성화
                    cam = torch.sum(weights * act, dim=1, keepdim=True)
                    cam = torch.relu(cam)  # ReLU로 음수 제거
                    
                    # 정규화
                    cam = cam.squeeze().cpu().numpy()
                    cam = (cam - cam.min()) / (cam.max() - cam.min() + 1e-8)
                    
                    # 224x224로 리사이즈
                    from scipy.ndimage import zoom
                    cam_resized = zoom(cam, (224 / cam.shape[0], 224 / cam.shape[1]))
                    
                    return cam_resized
                else:
                    # Fallback: 간단한 히트맵
                    return self._generate_simple_heatmap()
                    
            finally:
                handle_forward.remove()
                handle_backward.remove()
                self.model.eval()
                image_tensor.requires_grad_(False)
                
        except Exception as e:
            logger.error(f"Grad-CAM 히트맵 생성 실패: {e}", exc_info=True)
            # Fallback: 간단한 히트맵
            return self._generate_simple_heatmap()
    
    def _generate_simple_heatmap(self) -> np.ndarray:
        """간단한 히트맵 생성 (Fallback)"""
        # 중앙 영역을 강조하는 간단한 히트맵
        center_y, center_x = 112, 112
        y, x = np.ogrid[:224, :224]
        mask = np.exp(-((x - center_x)**2 + (y - center_y)**2) / (2 * 50**2))
        return mask
    
    def heatmap_to_base64(self, heatmap: np.ndarray, original_image_bytes: bytes) -> str:
        """히트맵을 Base64 인코딩된 이미지로 변환"""
        try:
            # 원본 이미지 로드
            original_image = Image.open(io.BytesIO(original_image_bytes))
            original_image = original_image.convert('RGB')
            original_array = np.array(original_image.resize((224, 224), Image.Resampling.LANCZOS))
            
            # 히트맵을 0-255 범위로 변환 (2D 배열)
            if len(heatmap.shape) == 2:
                heatmap_normalized = (heatmap * 255).astype(np.uint8)
                
                # 컬러맵 적용 (빨강-노랑 히트맵)
                try:
                    from matplotlib import colormaps
                    colormap = colormaps['jet']
                except (ImportError, KeyError):
                    import matplotlib.cm as cm
                    colormap = cm.get_cmap('jet')
                heatmap_colored = colormap(heatmap)[:, :, :3]  # RGB만
                heatmap_colored = (heatmap_colored * 255).astype(np.uint8)
                
                # 원본 이미지와 히트맵 블렌딩
                heatmap_resized = Image.fromarray(heatmap_colored).resize(
                    (original_array.shape[1], original_array.shape[0]), 
                    Image.Resampling.LANCZOS
                )
                original_pil = Image.fromarray(original_array)
                
                # 블렌딩 (히트맵 강도 조절)
                blended = Image.blend(original_pil, heatmap_resized, alpha=0.4)
            else:
                # Fallback: 원본 이미지만 반환
                blended = Image.fromarray(original_array)
            
            # Base64 인코딩
            buffer = io.BytesIO()
            blended.save(buffer, format='PNG')
            img_str = base64.b64encode(buffer.getvalue()).decode()
            
            return f"data:image/png;base64,{img_str}"
        except Exception as e:
            logger.error(f"히트맵 인코딩 실패: {e}", exc_info=True)
            return ""

# 전역 서비스 인스턴스 (싱글톤)
_skin_service: Optional[SkinAnalysisService] = None

def get_skin_service() -> SkinAnalysisService:
    """싱글톤 패턴으로 서비스 인스턴스 반환"""
    global _skin_service
    if _skin_service is None:
        _skin_service = SkinAnalysisService()
    return _skin_service
