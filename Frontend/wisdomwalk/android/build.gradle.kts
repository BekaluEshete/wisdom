// android/build.gradle.kts   ← PROJECT-LEVEL (not the app module one)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // REQUIRED for reliable 16 KB page size support
        classpath("com.android.tools.build:gradle:8.7.3")

        // Kotlin plugin (required by Flutter)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")

        // Optional but recommended if you use any Google services / Firebase
        // classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ──────────────────────────────────────────────────────────────
// Clean & unified build directory (keeps things tidy)
rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

// Ensure :app is configured first (helps some edge cases)
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}