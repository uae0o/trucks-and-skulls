using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using System.IO;

public class BuildScript
{
    public static void BuildIOS()
    {
        Debug.Log("[BuildScript] Starting iOS export...");

        // 1. Create MainScene if not present
        string sceneDir = "Assets/Scenes";
        string scenePath = Path.Combine(sceneDir, "MainScene.unity");
        if (!Directory.Exists(sceneDir))
        {
            Directory.CreateDirectory(sceneDir);
        }

        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        // Add Main Camera
        GameObject camObj = new GameObject("Main Camera");
        Camera cam = camObj.AddComponent<Camera>();
        cam.orthographic = true;
        cam.orthographicSize = 8f;
        camObj.AddComponent<AudioListener>();
        camObj.tag = "MainCamera";
        camObj.transform.position = new Vector3(0, 0, -10);

        // Add Core Systems
        GameObject coreObj = new GameObject("GameManager");
        coreObj.AddComponent<TrucksAndSkulls.GameManager>();
        coreObj.AddComponent<TrucksAndSkulls.LevelParser>();
        coreObj.AddComponent<TrucksAndSkulls.GamePhysics>();

        EditorSceneManager.SaveScene(scene, scenePath);
        Debug.Log($"[BuildScript] Created scene at {scenePath}");

        // 2. Set iOS Player Settings
        PlayerSettings.bundleVersion = "1.0.0";
        PlayerSettings.applicationIdentifier = "com.appyentertainment.trucksandskulls";
        PlayerSettings.productName = "Trucks & Skulls";
        PlayerSettings.companyName = "Appy Entertainment";
        PlayerSettings.iOS.targetOSVersionString = "12.0";
        PlayerSettings.iOS.sdkVersion = iOSSdkVersion.DeviceSDK;
        PlayerSettings.SetArchitecture(BuildTargetGroup.iOS, 1); // 1 = ARM64

        // 3. Export to Xcode
        string outputDir = "build/iOS";
        if (Directory.Exists(outputDir))
        {
            Directory.Delete(outputDir, true);
        }
        Directory.CreateDirectory(outputDir);

        BuildPlayerOptions buildPlayerOptions = new BuildPlayerOptions();
        buildPlayerOptions.scenes = new string[] { scenePath };
        buildPlayerOptions.locationPathName = outputDir;
        buildPlayerOptions.target = BuildTarget.iOS;
        buildPlayerOptions.options = BuildOptions.None;

        Debug.Log("[BuildScript] Invoking BuildPipeline.BuildPlayer for iOS...");
        var report = BuildPipeline.BuildPlayer(buildPlayerOptions);
        Debug.Log($"[BuildScript] Build finished with result: {report.summary.result}");
    }
}
