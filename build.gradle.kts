plugins {
    java
    `maven-publish`
}

val semver: String by project
val toolchainImage = "sedna-cpm-toolchain:1"

version = semver
group = "li.cil.sedna"

java.toolchain.languageVersion = JavaLanguageVersion.of(21)

repositories {
    mavenCentral()
}

val cpm22Sources = layout.projectDirectory.dir("external/cpm22")
val hawleyTools = layout.projectDirectory.dir("vendor/hawley")
val driUtilSources = layout.projectDirectory.dir("external/cpm22-utils")
val outputDir = layout.buildDirectory.dir("cpm")
val buildToolchainImage by tasks.registering(Exec::class) {
    description = "Builds the container holding Macro Assembler AS and cpmtools."
    inputs.file("Dockerfile")
    outputs.file(layout.buildDirectory.file("toolchain-image.stamp"))
    commandLine("docker", "build", "-q", "-t", toolchainImage, ".")
    doLast {
        outputs.files.singleFile.apply { parentFile.mkdirs() }.writeText(toolchainImage)
    }
}

val compileCpm by tasks.registering(Exec::class) {
    description = "Assembles CP/M 2.2 and the CBIOS, and builds the floppy image."
    dependsOn(buildToolchainImage)

    inputs.file("Makefile")
    inputs.dir("src/main/asm")
    inputs.dir("src/main/diskdefs")
    inputs.dir(cpm22Sources)
    inputs.dir(hawleyTools)
    inputs.dir(driUtilSources)
    outputs.dir(outputDir)

    doFirst {
        require(cpm22Sources.file("ccp.asm").asFile.exists()) {
            "external/cpm22 is empty; run `git submodule update --init`."
        }
        require(driUtilSources.file("src/ed.plm").asFile.exists()) {
            "external/cpm22-utils is empty; run `git submodule update --init --recursive`."
        }
        require(hawleyTools.file("zmac.com").asFile.exists()) {
            "vendor/hawley is missing the assembler; see its README.md."
        }
    }

    val uid = providers.exec { commandLine("id", "-u") }.standardOutput.asText.get().trim()
    val gid = providers.exec { commandLine("id", "-g") }.standardOutput.asText.get().trim()
    commandLine(
        "docker", "run", "--rm",
        "-u", "$uid:$gid",
        "-v", "${projectDir}:/build",
        "-w", "/build",
        toolchainImage, "make",
    )
}

tasks.processResources {
    dependsOn(compileCpm)
    from(outputDir) {
        include("bootrom.bin", "cpm.img", "geometry.properties")
        into("generated")
    }
}

tasks.jar {
    archiveVersion = semver
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            groupId = project.group.toString()
            artifactId = project.name
            version = semver
            artifact(tasks.jar)

            pom {
                name = "Sedna CP/M"
                description = "Prebuilt CP/M 2.2 boot ROM and floppy image for the Sedna emulator's Z80 board."
                url = "https://github.com/fnuecke/sedna-cpm"
                licenses {
                    license {
                        name = "MIT License"
                        url = "https://github.com/fnuecke/sedna-cpm/blob/main/LICENSE"
                    }
                }
                developers {
                    developer {
                        id = "fnuecke"
                        name = "Florian Nücke"
                    }
                }
            }
        }
    }
    repositories {
        val mavenRepoDir = project.findProperty("mavenRepoDir")?.toString()
        if (mavenRepoDir != null) {
            maven {
                name = "StaticMavenRepo"
                url = uri(file(mavenRepoDir))
            }
        }
    }
}
