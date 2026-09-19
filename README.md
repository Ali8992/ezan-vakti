# Ezan Vakti 🕌

Diyanet uyumlu (Aladhan API, method 13) namaz vakitleri uygulaması.

- 81 il şehir seçimi, arama ile
- Sıradaki vakte kalan süre (canlı sayaç)
- Hicri + Miladi tarih
- Koyu yeşil + sarı cami temalı hoş arayüz
- Uygulama simgesi: sarı cami

## Kurulum (geliştirici)

```bash
cd ezan_vakti
flutter pub get
flutter run
```

## GitHub'a push + APK

1. GitHub'da yeni boş repo açın, örn: `ezan-vakti`
2. Şunları çalıştırın:

```bash
cd C:\Users\megat\ezan_vakti
git init
git add .
git commit -m "Ezan Vakti ilk sürüm"
git branch -M main
git remote add origin https://github.com/KULLANICI_ADIN/ezan-vakti.git
git push -u origin main
```

3. Push sonrası GitHub Actions otomatik APK derler:
   - Repo > **Actions** > **APK Build** > en son run > **Artifacts: ezan-vakti-apk** > `app-release.apk` indir
   - Telefona atıp kurun (Bilinmeyen kaynaklara izin ver)

## APK'yı yerelde derleme (Android SDK varsa)

```bash
flutter build apk --release
# çıktı: build/app/outputs/flutter-apk/app-release.apk
```

## API

https://api.aladhan.com/v1/timingsByCity?city=Istanbul&country=Turkey&method=13
