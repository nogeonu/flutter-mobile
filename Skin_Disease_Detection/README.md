# 🔬 피부 질환 감지 AI 모델 (MobileNet + PyTorch)

모바일 환경에서 피부암 및 피부 질환을 감지할 수 있는 경량 딥러닝 모델입니다.

## 📋 프로젝트 개요

- **목적**: 피부에 생긴 흑점, 점, 병변 등을 촬영하여 7가지 피부 질환을 분류
- **데이터셋**: HAM10000 (10,000개 이상의 피부 병변 이미지)
- **모델**: MobileNetV2 (모바일/임베디드 환경에 최적화된 경량 모델)
- **프레임워크**: PyTorch (GPU 지원 우수)
- **출력**: ONNX 형식 (Flutter 앱 통합 가능)

## 🎯 감지 가능한 피부 질환 (7가지)

1. **akiec** - Actinic keratoses (광선각화증)
2. **bcc** - Basal cell carcinoma (기저세포암)
3. **bkl** - Benign keratosis-like lesions (양성 각화증)
4. **df** - Dermatofibroma (피부섬유종)
5. **mel** - Melanoma (흑색종)
6. **nv** - Melanocytic nevi (멜라닌 세포 모반)
7. **vasc** - Vascular lesions (혈관 병변)

## 🚀 시작하기

### 1. 환경 설정

```bash
# Python 3.8 이상 필요
python --version

# 필수 패키지 설치
pip install -r requirements.txt
```

### 2. Jupyter 노트북 실행

```bash
# PyTorch 버전 노트북 실행 (권장)
jupyter notebook skin_disease_mobilenet_training_pytorch.ipynb
```

### 3. 학습 진행

노트북의 셀을 순서대로 실행하면 다음 과정이 자동으로 진행됩니다:

1. ✅ 데이터 로드 및 전처리
2. ✅ 데이터 탐색 및 시각화
3. ✅ 데이터 증강 설정
4. ✅ MobileNetV2 모델 구축
5. ✅ 전이 학습 (1단계)
6. ✅ 미세 조정 (2단계)
7. ✅ 모델 평가 및 시각화
8. ✅ TFLite 변환 (모바일용)

## 📊 데이터셋 구조

```
Skin_Disease_Detection/
├── HAM10000_metadata.csv          # 메타데이터 (10,017개 레코드)
├── processed_images_dataset/
│   └── processed_images/          # 이미지 파일 (35,346개 JPG)
├── skin_disease_mobilenet_training_pytorch.ipynb  # PyTorch 학습 노트북
├── requirements.txt               # 필수 패키지 목록
└── models/                        # 학습된 모델 저장 (자동 생성)
    ├── mobilenet_skin_disease_best_stage1.pth
    ├── mobilenet_skin_disease_finetuned.pth
    ├── skin_disease_mobilenet.onnx  # Flutter/모바일용
    └── labels.json                # 클래스 레이블
```

## 📱 Flutter 앱 통합 가이드

### 1. 모델 파일 복사

학습 완료 후 `models/` 폴더에서 다음 파일을 Flutter 프로젝트로 복사:
- `skin_disease_mobilenet.onnx`
- `labels.json`

### 2. Flutter 프로젝트 설정

```yaml
# pubspec.yaml
dependencies:
  onnxruntime: ^1.14.0  # ONNX 런타임
  image_picker: ^1.0.0
  image: ^4.0.0

flutter:
  assets:
    - assets/skin_disease_mobilenet.onnx
    - assets/labels.json
```

### 3. 패키지 설치

```bash
flutter pub get
```

### 4. 사용 예시 (Python - PyTorch)

```python
import torch
from torchvision import transforms, models
from PIL import Image

# 모델 로드
model = models.mobilenet_v2()
model.classifier = torch.nn.Sequential(
    torch.nn.Dropout(0.5),
    torch.nn.Linear(1280, 256),
    torch.nn.ReLU(),
    torch.nn.BatchNorm1d(256),
    torch.nn.Dropout(0.3),
    torch.nn.Linear(256, 7)
)
model.load_state_dict(torch.load('models/mobilenet_skin_disease_finetuned.pth'))
model.eval()

# 이미지 전처리
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# 예측
image = Image.open('test_image.jpg')
image_tensor = transform(image).unsqueeze(0)

with torch.no_grad():
    output = model(image_tensor)
    probs = torch.softmax(output, dim=1)
    pred_class = output.argmax(1).item()
    confidence = probs[0][pred_class].item()

print(f"예측 클래스: {pred_class}, 신뢰도: {confidence:.2%}")
```

## 🎨 모델 성능

학습 완료 후 다음 결과물이 생성됩니다:

- **학습 히스토리 그래프** (`training_history.png`)
- **혼동 행렬** (`confusion_matrix.png`)
- **클래스별 성능 지표** (`class_performance.png`)
- **예측 샘플** (`prediction_samples.png`)
- **모델 정보 요약** (`model_info.txt`)

## ⚠️ 중요 주의사항

1. **의료 기기가 아닙니다**: 이 모델은 교육 및 연구 목적으로 개발되었습니다.
2. **전문의 진단 필수**: 모델의 예측 결과는 참고용이며, 반드시 피부과 전문의의 진단을 받아야 합니다.
3. **임상 검증 필요**: 실제 의료 서비스로 사용하기 전에 임상 검증이 필요합니다.
4. **면책 조항**: 사용자에게 반드시 전문의 상담을 권장하는 안내를 포함해야 합니다.

## 🛠️ 시스템 요구사항

- **Python**: 3.8 이상
- **RAM**: 8GB 이상 권장
- **GPU**: CUDA 지원 GPU (선택사항, 학습 속도 향상)
- **저장공간**: 최소 5GB (데이터셋 + 모델)

## 📚 학습 파라미터

- **입력 크기**: 224 x 224 x 3
- **배치 크기**: 32
- **에포크**: 1단계 30 + 2단계 20 = 총 50
- **학습률**: 1단계 0.001 → 2단계 0.0001
- **최적화**: Adam
- **손실 함수**: Categorical Crossentropy
- **데이터 분할**: 학습 70% / 검증 15% / 테스트 15%

## 📈 개선 방안

1. **데이터 증강**: 더 다양한 증강 기법 적용
2. **앙상블**: 여러 모델의 예측 결합
3. **클래스 불균형**: SMOTE, 오버샘플링 등 적용
4. **하이퍼파라미터 튜닝**: Grid Search, Bayesian Optimization
5. **최신 모델**: EfficientNet, Vision Transformer 등 시도

## 📞 문의 및 기여

- 버그 리포트: Issues 탭 활용
- 기능 제안: Pull Request 환영
- 문의사항: 이메일로 연락

## 📄 라이선스

이 프로젝트는 교육 및 연구 목적으로 제공됩니다.

---

**⚕️ 건강은 소중합니다. 피부에 이상이 있다면 반드시 전문의와 상담하세요!**

