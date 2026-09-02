# Fix Build Failure (Error 25.0.2)

The build failure is caused by a combination of incorrect SDK paths in `local.properties`, an incompatible JDK version (Java 25), and a conflict between environment variables.

## User Review Required

> [!IMPORTANT]
> The project was using JDK 25 (from the bundled Android Studio JBR), which is currently incompatible with Gradle 8.14. I am switching the project to use JDK 17, which is installed at `C:\Program Files\Eclipse Adoptium\jdk-17.0.14.7-hotspot`.
>
> Also, ensure that the environment variable `ANDROID_PREFS_ROOT` is either removed or set to the same value as `ANDROID_USER_HOME` if conflicts persist in your terminal environment.

## Proposed Changes

### [Component] Gradle Configuration

#### [MODIFY] [local.properties](file:///C:/Users/SACHIN/AndroidStudioProjects/WorkoutApp/local.properties)
Update SDK and Flutter paths to match the current user (`SACHIN`) and environment.

#### [MODIFY] [android/local.properties](file:///C:/Users/SACHIN/AndroidStudioProjects/WorkoutApp/android/local.properties)
Ensure consistency with the root `local.properties`.

#### [MODIFY] [android/gradle.properties](file:///C:/Users/SACHIN/AndroidStudioProjects/WorkoutApp/android/gradle.properties)
Explicitly set `org.gradle.java.home` to a compatible JDK version to avoid the `25.0.2` crash.

## Verification Plan

### Automated Tests
- Run `./gradlew assembleDebug` to verify the build configuration.
- Run `flutter build apk --debug` to ensure the Flutter wrapper correctly initiates the build.

### Manual Verification
- Check that the APK is generated in `build/app/outputs/flutter-apk/app-debug.apk`.
