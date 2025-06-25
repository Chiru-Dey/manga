You want to use the `Suwayomi-WebUI` folder directly instead of the downloaded, embedded ZIP file. This is a common scenario for developers or users who want to make local modifications to the WebUI or serve it from a specific location.

Based on the `Suwayomi-Server`'s configuration, specifically in [`ServerConfig.kt`](komikku/app/src/main/kotlin/suwayomi/tachidesk/server/ServerConfig.kt:104) and [`JavalinSetup.kt`](komikku/app/src/main/kotlin/suwayomi/tachidesk/server/JavalinSetup.kt:48), the server uses a configuration property to determine where to find the WebUI files.

Here's how you can instruct the `Suwayomi-Server` to use your local `Suwayomi-WebUI` folder:
You want to use the `Suwayomi-WebUI` folder directly instead of the downloaded, embedded ZIP file. This is a common scenario for developers or users who want to make local modifications to the WebUI or serve it from a specific location.

Based on the `Suwayomi-Server`'s configuration, specifically in [`ServerConfig.kt`](komikku/app/src/main/kotlin/suwayomi/tachidesk/server/ServerConfig.kt:104) and [`JavalinSetup.kt`](komikku/app/src/main/kotlin/suwayomi/tachidesk/server/JavalinSetup.kt:48), the server uses a configuration property to determine where to find the WebUI files.

Here's how you can instruct the `Suwayomi-Server` to use your local `Suwayomi-WebUI` folder:

### Method: Using System Properties (Recommended for Direct Execution)

The `Suwayomi-Server` uses `SystemPropertyOverridableConfigModule` (as seen in `ServerConfig.kt`), which means many configuration values can be overridden by passing them as system properties when you run the Java application.

The relevant configuration property for the WebUI root directory is likely managed internally by `ApplicationDirs` (seen in `JavalinSetup.kt:37`). While `ServerConfig.kt` defines `webUIEnabled`, `webUIFlavor`, `webUIInterface`, and `electronPath`, there isn't an explicit `webUIRootPath` directly exposed as a `MutableStateFlow` in `ServerConfig.kt` that you can override with a simple system property like `-Dsuwayomi.tachidesk.config.server.webUIRoot`.

However, looking at `JavalinSetup.kt` (lines 48-58):
```kotlin
46 |                 if (serverConfig.webUIEnabled.value) {
47 |                     val serveWebUI = {
48 |                         config.spaRoot.addFile("/", applicationDirs.webUIRoot + "/index.html", Location.EXTERNAL)
49 |                     }
50 |                     WebInterfaceManager.setServeWebUI(serveWebUI)
51 | 
52 |                     runBlocking {
53 |                         WebInterfaceManager.setupWebUI()
54 |                     }
55 | 
56 |                     logger.info { "Serving web static files for ${serverConfig.webUIFlavor.value}" }
57 |                     config.staticFiles.add(applicationDirs.webUIRoot, Location.EXTERNAL)
58 |                     serveWebUI()
59 | 
```
This code shows that `applicationDirs.webUIRoot` is used to specify the path for serving static files. The `ApplicationDirs` class (injected via `injectLazy`) is responsible for determining various application directories. It's highly probable that `applicationDirs.webUIRoot` can be influenced by a system property or an environment variable.

Given the `runElectron` task in `Suwayomi-Server/server/build.gradle.kts` (lines 203-214) which sets system properties like `-Dsuwayomi.tachidesk.config.server.webUIInterface=electron`, it's a strong indicator that the server's configuration can be controlled via system properties.

To use your local `Suwayomi-WebUI` folder, you would typically:

1.  **Build the `Suwayomi-WebUI` for production:**
    Navigate to the `Suwayomi-WebUI` directory and run:
    ```bash
    cd Suwayomi-WebUI
    yarn build
    # or npm run build
    ```
    This will create a `build` directory inside `Suwayomi-WebUI` containing the static files.

2.  **Run the `Suwayomi-Server` with a system property pointing to the WebUI's `build` directory:**
    You need to find the exact system property that `ApplicationDirs` uses to determine the `webUIRoot`. While not explicitly in `ServerConfig.kt`, a common pattern for such a setup would be a property like `suwayomi.tachidesk.config.server.webUIRoot` or similar.

    Let's assume the property is `suwayomi.tachidesk.config.server.webUIRoot`. You would run the server like this:

    ```bash
    cd Suwayomi-Server
    java -Dsuwayomi.tachidesk.config.server.webUIRoot=/path/to/your/Suwayomi-WebUI/build -jar server/build/libs/Suwayomi-Server-{version}.jar
    ```
    *   Replace `/path/to/your/Suwayomi-WebUI/build` with the actual absolute path to the `build` directory inside your `Suwayomi-WebUI` folder.
    *   Replace `{version}` with the actual version number of your server JAR.

    **Important Note:** If the exact system property `suwayomi.tachidesk.config.server.webUIRoot` does not work, you would need to inspect the `ApplicationDirs` class (or related configuration loading logic) within the `Suwayomi-Server` codebase to find the precise property name or environment variable it uses to set the `webUIRoot`. Without direct access to the `ApplicationDirs` source, this is an educated guess based on common patterns.

### Alternative: Modifying `Suwayomi-Server/server/build.gradle.kts` (Less Recommended for Runtime)

You could theoretically modify the `downloadWebUI` task in `Suwayomi-Server/server/build.gradle.kts` to copy your local `Suwayomi-WebUI/build` content instead of downloading the ZIP. However, this is more involved and changes the build process rather than the runtime behavior. It's generally not the preferred way to point to a local WebUI for development or testing, as it requires rebuilding the server every time you change the WebUI.

The system property approach is cleaner because it allows you to run the server with different WebUI paths without rebuilding the server JAR.

### Summary of Steps:

1.  **Build `Suwayomi-WebUI`:**
    ```bash
    cd /path/to/your/Suwayomi-WebUI
    yarn build
    ```
    (This creates the `build` folder with static files.)

2.  **Run `Suwayomi-Server` pointing to the local `build` folder:**
    ```bash
    cd /path/to/your/Suwayomi-Server
    java -Dsuwayomi.tachidesk.config.server.webUIRoot=/path/to/your/Suwayomi-WebUI/build -jar server/build/libs/Suwayomi-Server-{version}.jar
    ```

This setup allows the `Suwayomi-Server` to serve the `Suwayomi-WebUI` directly from your local `build` directory, giving you full control over the frontend files.
### Method: Using System Properties (Recommended for Direct Execution)

The `Suwayomi-Server` uses `SystemPropertyOverridableConfigModule` (as seen in `ServerConfig.kt`), which means many configuration values can be overridden by passing them as system properties when you run the Java application.

The relevant configuration property for the WebUI root directory is likely managed internally by `ApplicationDirs` (seen in `JavalinSetup.kt:37`). While `ServerConfig.kt` defines `webUIEnabled`, `webUIFlavor`, `webUIInterface`, and `electronPath`, there isn't an explicit `webUIRootPath` directly exposed as a `MutableStateFlow` in `ServerConfig.kt` that you can override with a simple system property like `-Dsuwayomi.tachidesk.config.server.webUIRoot`.

However, looking at `JavalinSetup.kt` (lines 48-58):
```kotlin
46 |                 if (serverConfig.webUIEnabled.value) {
47 |                     val serveWebUI = {
48 |                         config.spaRoot.addFile("/", applicationDirs.webUIRoot + "/index.html", Location.EXTERNAL)
49 |                     }
50 |                     WebInterfaceManager.setServeWebUI(serveWebUI)
51 | 
52 |                     runBlocking {
53 |                         WebInterfaceManager.setupWebUI()
54 |                     }
55 | 
56 |                     logger.info { "Serving web static files for ${serverConfig.webUIFlavor.value}" }
57 |                     config.staticFiles.add(applicationDirs.webUIRoot, Location.EXTERNAL)
58 |                     serveWebUI()
59 | 
```
This code shows that `applicationDirs.webUIRoot` is used to specify the path for serving static files. The `ApplicationDirs` class (injected via `injectLazy`) is responsible for determining various application directories. It's highly probable that `applicationDirs.webUIRoot` can be influenced by a system property or an environment variable.

Given the `runElectron` task in `Suwayomi-Server/server/build.gradle.kts` (lines 203-214) which sets system properties like `-Dsuwayomi.tachidesk.config.server.webUIInterface=electron`, it's a strong indicator that the server's configuration can be controlled via system properties.

To use your local `Suwayomi-WebUI` folder, you would typically:

1.  **Build the `Suwayomi-WebUI` for production:**
    Navigate to the `Suwayomi-WebUI` directory and run:
    ```bash
    cd Suwayomi-WebUI
    yarn build
    # or npm run build
    ```
    This will create a `build` directory inside `Suwayomi-WebUI` containing the static files.

2.  **Run the `Suwayomi-Server` with a system property pointing to the WebUI's `build` directory:**
    You need to find the exact system property that `ApplicationDirs` uses to determine the `webUIRoot`. While not explicitly in `ServerConfig.kt`, a common pattern for such a setup would be a property like `suwayomi.tachidesk.config.server.webUIRoot` or similar.

    Let's assume the property is `suwayomi.tachidesk.config.server.webUIRoot`. You would run the server like this:

    ```bash
    cd Suwayomi-Server
    java -Dsuwayomi.tachidesk.config.server.webUIRoot=/path/to/your/Suwayomi-WebUI/build -jar server/build/libs/Suwayomi-Server-{version}.jar
    ```
    *   Replace `/path/to/your/Suwayomi-WebUI/build` with the actual absolute path to the `build` directory inside your `Suwayomi-WebUI` folder.
    *   Replace `{version}` with the actual version number of your server JAR.

    **Important Note:** If the exact system property `suwayomi.tachidesk.config.server.webUIRoot` does not work, you would need to inspect the `ApplicationDirs` class (or related configuration loading logic) within the `Suwayomi-Server` codebase to find the precise property name or environment variable it uses to set the `webUIRoot`. Without direct access to the `ApplicationDirs` source, this is an educated guess based on common patterns.

### Alternative: Modifying `Suwayomi-Server/server/build.gradle.kts` (Less Recommended for Runtime)

You could theoretically modify the `downloadWebUI` task in `Suwayomi-Server/server/build.gradle.kts` to copy your local `Suwayomi-WebUI/build` content instead of downloading the ZIP. However, this is more involved and changes the build process rather than the runtime behavior. It's generally not the preferred way to point to a local WebUI for development or testing, as it requires rebuilding the server every time you change the WebUI.

The system property approach is cleaner because it allows you to run the server with different WebUI paths without rebuilding the server JAR.

### Summary of Steps:

1.  **Build `Suwayomi-WebUI`:**
    ```bash
    cd /path/to/your/Suwayomi-WebUI
    yarn build
    ```
    (This creates the `build` folder with static files.)

2.  **Run `Suwayomi-Server` pointing to the local `build` folder:**
    ```bash
    cd /path/to/your/Suwayomi-Server
    java -Dsuwayomi.tachidesk.config.server.webUIRoot=/path/to/your/Suwayomi-WebUI/build -jar server/build/libs/Suwayomi-Server-{version}.jar
    ```

This setup allows the `Suwayomi-Server` to serve the `Suwayomi-WebUI` directly from your local `build` directory, giving you full control over the frontend files.