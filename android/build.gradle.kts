import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}



// Set custom build output directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Apply resolution strategy to force the correct google-services version
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.google.gms" && requested.name == "google-services") {
                useVersion("4.4.2")
                because("Ensure consistent google-services plugin version across classpath and plugins block")
            }
        }
    }

    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
apply(plugin = "com.google.gms.google-services")

