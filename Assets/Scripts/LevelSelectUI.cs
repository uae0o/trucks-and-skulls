using System.Collections.Generic;
using UnityEngine;

namespace TrucksAndSkulls
{
    public class LevelSelectUI : MonoBehaviour
    {
        public static LevelSelectUI Instance { get; private set; }

        public bool isVisible = false;
        private EpisodeData currentEpisode;
        private Vector2 scrollPos;

        private void Awake()
        {
            if (Instance == null) Instance = this;
            else Destroy(gameObject);
        }

        public void ShowEpisode(EpisodeData episode)
        {
            currentEpisode = episode;
            isVisible = true;
        }

        public void Hide()
        {
            isVisible = false;
        }

        private void OnGUI()
        {
            if (!isVisible || currentEpisode == null) return;

            GUI.skin.label.fontSize = 22;
            GUI.skin.button.fontSize = 18;

            GUI.Box(new Rect(40, 40, Screen.width - 80, Screen.height - 80), $"{currentEpisode.name} - SELECT LEVEL");

            int cols = 4;
            int btnW = 140;
            int btnH = 60;
            int spacing = 15;
            int rows = Mathf.CeilToInt((float)currentEpisode.levels.Count / cols);

            scrollPos = GUI.BeginScrollView(
                new Rect(60, 90, Screen.width - 120, Screen.height - 160),
                scrollPos,
                new Rect(0, 0, cols * (btnW + spacing), rows * (btnH + spacing) + 30)
            );

            for (int i = 0; i < currentEpisode.levels.Count; i++)
            {
                int r = i / cols;
                int c = i % cols;
                string levelFile = currentEpisode.levels[i];

                Rect btnRect = new Rect(c * (btnW + spacing), r * (btnH + spacing), btnW, btnH);
                if (GUI.Button(btnRect, $"Level {i + 1}\n{levelFile}"))
                {
                    Hide();
                    if (GameManager.Instance != null)
                    {
                        GameManager.Instance.LoadLevel(levelFile);
                    }
                }
            }

            GUI.EndScrollView();

            if (GUI.Button(new Rect(60, Screen.height - 80, 120, 35), "BACK"))
            {
                Hide();
                if (EpisodeSelectUI.Instance != null)
                {
                    EpisodeSelectUI.Instance.Show();
                }
            }
        }
    }
}
