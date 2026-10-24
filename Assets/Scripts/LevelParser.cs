using System.IO;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;

namespace TrucksAndSkulls
{
    public class LevelParser : MonoBehaviour
    {
        public static LevelParser Instance { get; private set; }

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }

        public string GetStreamingAssetPath(string subPath)
        {
            return Path.Combine(Application.streamingAssetsPath, subPath);
        }

        public LevelData LoadLevel(string levelFileName)
        {
            if (levelFileName.EndsWith(".POND") || levelFileName.EndsWith(".json"))
            {
                levelFileName = Path.GetFileNameWithoutExtension(levelFileName);
            }

            string relativePath = Path.Combine("Levels", levelFileName + ".json");
            string fullPath = GetStreamingAssetPath(relativePath);

            string jsonContent = "";
            if (fullPath.Contains("://") || fullPath.Contains(":///"))
            {
                UnityWebRequest req = UnityWebRequest.Get(fullPath);
                req.SendWebRequest();
                while (!req.isDone) { }
                if (req.result == UnityWebRequest.Result.Success)
                {
                    jsonContent = req.downloadHandler.text;
                }
            }
            else if (File.Exists(fullPath))
            {
                jsonContent = File.ReadAllText(fullPath);
            }

            if (string.IsNullOrEmpty(jsonContent))
            {
                Debug.LogError($"[LevelParser] Failed to load level JSON: {fullPath}");
                return null;
            }

            try
            {
                LevelData data = JsonUtility.FromJson<LevelData>(jsonContent);
                return data;
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"[LevelParser] Json parsing error: {ex.Message}");
                return null;
            }
        }

        public List<EpisodeData> LoadEpisodes()
        {
            string fullPath = GetStreamingAssetPath("episodes.json");
            string jsonContent = "";

            if (fullPath.Contains("://") || fullPath.Contains(":///"))
            {
                UnityWebRequest req = UnityWebRequest.Get(fullPath);
                req.SendWebRequest();
                while (!req.isDone) { }
                if (req.result == UnityWebRequest.Result.Success)
                    jsonContent = req.downloadHandler.text;
            }
            else if (File.Exists(fullPath))
            {
                jsonContent = File.ReadAllText(fullPath);
            }

            if (string.IsNullOrEmpty(jsonContent))
            {
                Debug.LogWarning("[LevelParser] Could not load episodes.json");
                return new List<EpisodeData>();
            }

            string wrappedJson = "{\"items\":" + jsonContent + "}";
            EpisodeListWrapper wrapper = JsonUtility.FromJson<EpisodeListWrapper>(wrappedJson);
            return wrapper != null ? wrapper.items : new List<EpisodeData>();
        }

        [System.Serializable]
        private class EpisodeListWrapper
        {
            public List<EpisodeData> items;
        }
    }
}
