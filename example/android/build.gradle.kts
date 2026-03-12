allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        mavenCentral()
        // 阿里云公共仓库（用于下载 alicloud-httpdns 等公共依赖）
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven {
            val polyvRepoUser = (project.findProperty("polyvRepoUser") as String?)?.takeIf { it.isNotBlank() }
            val polyvRepoPassword = (project.findProperty("polyvRepoPassword") as String?)?.takeIf { it.isNotBlank() }
            if (polyvRepoUser != null && polyvRepoPassword != null) {
                credentials {
                    username = polyvRepoUser
                    password = polyvRepoPassword
                }
            }
            url = uri("https://packages.aliyun.com/maven/repository/2102846-release-8EVsoM/")
        }
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
