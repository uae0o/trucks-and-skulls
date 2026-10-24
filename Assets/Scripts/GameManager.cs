using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace TrucksAndSkulls
{
    public enum GameState
    {
        Menu,
        Loading,
        Playing,
        Won,
        Lost
    }

    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        public GameState currentState = GameState.Menu;
        public string currentLevelName = "Ambush";
        public int score = 0;

        private List<StructurePart> activeSkulls = new List<StructurePart>();
        private List<TruckType> remainingTrucks = new List<TruckType>();
        private LevelData currentLevelData;
        private bool isLevelCompleted = false;

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

        private void Start()
        {
            // Auto start first level if in main scene
            if (currentState == GameState.Menu)
            {
                LoadLevel("Ambush");
            }
        }

        public void LoadLevel(string levelName)
        {
            currentLevelName = levelName;
            currentState = GameState.Loading;
            isLevelCompleted = false;
            activeSkulls.Clear();
            remainingTrucks.Clear();
            score = 0;

            if (LevelParser.Instance == null)
            {
                gameObject.AddComponent<LevelParser>();
            }

            currentLevelData = LevelParser.Instance.LoadLevel(levelName);
            if (currentLevelData == null)
            {
                Debug.LogError($"[GameManager] Cannot load level {levelName}");
                return;
            }

            // Parse projectiles
            foreach (var p in currentLevelData.projectiles)
            {
                remainingTrucks.Add(ParseTruckType(p));
            }
            if (remainingTrucks.Count == 0)
            {
                remainingTrucks.Add(TruckType.Bomber);
                remainingTrucks.Add(TruckType.CrotchRocket);
                remainingTrucks.Add(TruckType.Dart);
            }

            // Setup Physics & World
            if (GamePhysics.Instance == null)
            {
                gameObject.AddComponent<GamePhysics>();
            }
            GamePhysics.Instance.SpawnLevel(currentLevelData);

            // Setup Launcher
            Vector2 launcherPos = new Vector2(currentLevelData.launcherX * GamePhysics.SCALE, currentLevelData.launcherY * GamePhysics.SCALE);
            if (TruckLauncher.Instance == null)
            {
                GameObject launcherObj = new GameObject("TruckLauncher");
                launcherObj.AddComponent<TruckLauncher>();
            }
            TruckLauncher.Instance.SetupLauncher(launcherPos);

            // Setup Camera
            if (CameraController.Instance == null && Camera.main != null)
            {
                Camera.main.gameObject.AddComponent<CameraController>();
            }
            if (CameraController.Instance != null)
            {
                CameraController.Instance.SetLevelBounds(currentLevelData.width, currentLevelData.height, launcherPos);
            }

            currentState = GameState.Playing;
            PrepareNextTruckInQueue();
        }

        public void RegisterSkull(StructurePart skull)
        {
            if (!activeSkulls.Contains(skull))
            {
                activeSkulls.Add(skull);
            }
        }

        public void OnSkullDestroyed(StructurePart skull)
        {
            activeSkulls.Remove(skull);
            AddScore(1000);

            if (activeSkulls.Count == 0 && !isLevelCompleted)
            {
                StartCoroutine(CheckWinDelay());
            }
        }

        public void AddScore(int amount)
        {
            score += amount;
        }

        public void OnTruckFired()
        {
            // Fired
        }

        public void OnTruckSettled()
        {
            if (CameraController.Instance != null)
            {
                CameraController.Instance.ResetToLauncher();
            }

            if (activeSkulls.Count == 0)
            {
                TriggerWin();
                return;
            }

            if (remainingTrucks.Count > 0)
            {
                PrepareNextTruckInQueue();
            }
            else
            {
                StartCoroutine(CheckLossDelay());
            }
        }

        private void PrepareNextTruckInQueue()
        {
            if (remainingTrucks.Count > 0)
            {
                TruckType nextTruck = remainingTrucks[0];
                remainingTrucks.RemoveAt(0);
                TruckLauncher.Instance.PrepareNextTruck(nextTruck);
            }
        }

        private IEnumerator CheckWinDelay()
        {
            yield return new WaitForSeconds(1.2f);
            if (activeSkulls.Count == 0)
            {
                TriggerWin();
            }
        }

        private IEnumerator CheckLossDelay()
        {
            yield return new WaitForSeconds(2.0f);
            if (activeSkulls.Count > 0 && remainingTrucks.Count == 0)
            {
                TriggerLoss();
            }
        }

        private void TriggerWin()
        {
            if (isLevelCompleted) return;
            isLevelCompleted = true;
            currentState = GameState.Won;
            score += (remainingTrucks.Count + 1) * 2000; // Remaining truck bonus
        }

        private void TriggerLoss()
        {
            if (isLevelCompleted) return;
            isLevelCompleted = true;
            currentState = GameState.Lost;
        }

        public bool IsGameOver()
        {
            return currentState == GameState.Won || currentState == GameState.Lost;
        }

        private TruckType ParseTruckType(string name)
        {
            if (name.Contains("Bomber")) return TruckType.Bomber;
            if (name.Contains("Bus")) return TruckType.Bus;
            if (name.Contains("CrotchRocket")) return TruckType.CrotchRocket;
            if (name.Contains("Dart")) return TruckType.Dart;
            if (name.Contains("Doomstone")) return TruckType.Doomstone;
            if (name.Contains("MIRV")) return TruckType.MIRV;
            return TruckType.Bomber;
        }

        private void OnGUI()
        {
            // Simple robust in-game HUD for quick play and mobile testing
            GUI.skin.label.fontSize = 22;
            GUI.skin.button.fontSize = 20;

            GUI.Label(new Rect(30, 25, 400, 35), $"LEVEL: {currentLevelName}");
            GUI.Label(new Rect(30, 60, 400, 35), $"SCORE: {score}");
            GUI.Label(new Rect(30, 95, 400, 35), $"SKULLS: {activeSkulls.Count} | TRUCKS: {remainingTrucks.Count + 1}");

            if (GUI.Button(new Rect(Screen.width - 160, 25, 130, 45), "RESTART"))
            {
                LoadLevel(currentLevelName);
            }

            if (currentState == GameState.Won)
            {
                GUI.Box(new Rect(Screen.width / 2 - 180, Screen.height / 2 - 120, 360, 240), "");
                GUI.Label(new Rect(Screen.width / 2 - 120, Screen.height / 2 - 90, 240, 40), "★ VICTORY! ★");
                GUI.Label(new Rect(Screen.width / 2 - 120, Screen.height / 2 - 45, 240, 40), $"TOTAL SCORE: {score}");

                if (GUI.Button(new Rect(Screen.width / 2 - 100, Screen.height / 2 + 10, 200, 45), "NEXT LEVEL"))
                {
                    LoadLevel("Arachnoid");
                }
                if (GUI.Button(new Rect(Screen.width / 2 - 100, Screen.height / 2 + 65, 200, 40), "REPLAY"))
                {
                    LoadLevel(currentLevelName);
                }
            }
            else if (currentState == GameState.Lost)
            {
                GUI.Box(new Rect(Screen.width / 2 - 180, Screen.height / 2 - 100, 360, 200), "");
                GUI.Label(new Rect(Screen.width / 2 - 120, Screen.height / 2 - 70, 240, 40), "SKULLS SURVIVED!");

                if (GUI.Button(new Rect(Screen.width / 2 - 100, Screen.height / 2 - 15, 200, 45), "TRY AGAIN"))
                {
                    LoadLevel(currentLevelName);
                }
            }
        }
    }
}
