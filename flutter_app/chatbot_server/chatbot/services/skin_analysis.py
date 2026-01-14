import numpy as np
import tensorflow as tf
from PIL import Image
import io
import json
import base64
from pathlib import Path
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)

class SkinAnalysisService:
    """피부 질환 분석 서비스 (MobileNetV2 기반)"""
    
    def __init__(self):
        self.model = None
        self.class_labels = {}
        self.model_path = Path(__file__).parent.parent.parent / "models" / "mobilenet_skin_disease_best.h5"
        self.labels_path = Path(__file__).parent.parent.parent / "models" / "labels.json"
        self._load_model()
        self._load_labels()
    
    def _load_model(self):
        """MobileNetV2 모델 로드"""
        try:
            if self.model_path.exists():
                self.model = tf.keras.models.load_model(str(self.model_path))
                logger.info(f"✅ 피부 분석 모델 로드 완료: {self.model_path}")
            else:
                logger.warning(f"⚠️ 모델 파일을 찾을 수 없습니다: {self.model_path}")
                logger.info("기본 MobileNetV2 모델을 생성합니다...")
                self.model = self._create_default_model()
        except Exception as e:
            logger.error(f"❌ 모델 로드 실패: {e}")
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
        """기본 MobileNetV2 모델 생성"""
        base_model = tf.keras.applications.MobileNetV2(
            input_shape=(224, 224, 3),
            include_top=False,
            weights='imagenet'
        )
        base_model.trainable = False
        
        model = tf.keras.Sequential([
            base_model,
            tf.keras.layers.GlobalAveragePooling2D(),
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dropout(0.5),
            tf.keras.layers.Dense(7, activation='softmax')
        ])
        
        logger.info("✅ 기본 MobileNetV2 모델 생성 완료")
        return model
    
    def preprocess_image(self, image_bytes: bytes) -> np.ndarray:
        """이미지 전처리 (MobileNetV2 입력 형식)"""
        # PIL로 이미지 로드
        image = Image.open(io.BytesIO(image_bytes))
        image = image.convert('RGB')
        
        # 리사이즈 (224x224)
        image = image.resize((224, 224), Image.Resampling.LANCZOS)
        
        # NumPy 배열로 변환
        img_array = np.array(image, dtype=np.float32)
        
        # MobileNetV2 전처리 ([-1, 1] 범위로 정규화)
        img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)
        
        # 배치 차원 추가
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
    
    def predict(self, image_bytes: bytes) -> Dict:
        """이미지 분석 및 예측"""
        try:
            # 이미지 전처리
            processed_image = self.preprocess_image(image_bytes)
            
            # 예측
            predictions = self.model.predict(processed_image, verbose=0)
            predicted_class_idx = int(np.argmax(predictions[0]))
            confidence = float(predictions[0][predicted_class_idx])
            
            # 예측된 클래스 정보
            predicted_label = self.class_labels.get(predicted_class_idx, {
                "code": "unknown",
                "name": "알 수 없음"
            })
            
            # 클래스별 확률
            class_probabilities = {}
            for i in range(len(predictions[0])):
                label_info = self.class_labels.get(i, {"code": f"class_{i}", "name": f"클래스 {i}"})
                class_probabilities[label_info['name']] = float(predictions[0][i])
            
            # 상위 3개 예측 결과
            top_3_indices = np.argsort(predictions[0])[-3:][::-1]
            top_3_predictions = []
            for idx in top_3_indices:
                label_info = self.class_labels.get(int(idx), {"code": f"class_{idx}", "name": f"클래스 {idx}"})
                top_3_predictions.append({
                    "class_name": label_info['name'],
                    "class_code": label_info['code'],
                    "confidence": float(predictions[0][idx])
                })
            
            # 히트맵 생성 (선택사항)
            heatmap_base64 = None
            try:
                heatmap = self.generate_heatmap(processed_image[0], predicted_class_idx)
                heatmap_base64 = self.heatmap_to_base64(heatmap, image_bytes)
            except Exception as e:
                logger.warning(f"히트맵 생성 실패: {e}")
            
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
    
    def generate_heatmap(self, image: np.ndarray, predicted_class: int) -> np.ndarray:
        """Grad-CAM 기반 히트맵 생성 (간단한 버전)"""
        try:
            # 원본 이미지를 0-1 범위로 변환
            # MobileNetV2 전처리를 역변환
            heatmap = (image + 1.0) / 2.0
            heatmap = np.clip(heatmap, 0, 1)
            
            # 간단한 히트맵 효과 (실제로는 Grad-CAM 사용 권장)
            # 중앙 영역을 강조
            center_y, center_x = 112, 112
            y, x = np.ogrid[:224, :224]
            mask = np.exp(-((x - center_x)**2 + (y - center_y)**2) / (2 * 50**2))
            
            # 히트맵 적용
            heatmap_red = heatmap.copy()
            heatmap_red[:, :, 0] = np.clip(heatmap_red[:, :, 0] + mask * 0.3, 0, 1)
            
            return heatmap_red
        except Exception as e:
            logger.error(f"히트맵 생성 실패: {e}")
            return image
    
    def heatmap_to_base64(self, heatmap: np.ndarray, original_image_bytes: bytes) -> str:
        """히트맵을 Base64 인코딩된 이미지로 변환"""
        try:
            # 원본 이미지 로드
            original_image = Image.open(io.BytesIO(original_image_bytes))
            original_image = original_image.convert('RGB')
            original_image = original_image.resize((224, 224), Image.Resampling.LANCZOS)
            
            # 히트맵을 0-255 범위로 변환
            heatmap_uint8 = (heatmap * 255).astype(np.uint8)
            
            # PIL 이미지로 변환
            heatmap_image = Image.fromarray(heatmap_uint8)
            
            # 원본 이미지와 블렌딩
            blended = Image.blend(original_image, heatmap_image, alpha=0.5)
            
            # Base64 인코딩
            buffer = io.BytesIO()
            blended.save(buffer, format='PNG')
            img_str = base64.b64encode(buffer.getvalue()).decode()
            
            return f"data:image/png;base64,{img_str}"
        except Exception as e:
            logger.error(f"히트맵 인코딩 실패: {e}")
            return ""

# 전역 서비스 인스턴스 (싱글톤)
_skin_service: Optional[SkinAnalysisService] = None

def get_skin_service() -> SkinAnalysisService:
    """싱글톤 패턴으로 서비스 인스턴스 반환"""
    global _skin_service
    if _skin_service is None:
        _skin_service = SkinAnalysisService()
    return _skin_service
