using System.Collections.Generic;
using UnityEngine;

namespace TrucksAndSkulls
{
    public class EpisodeSelectUI : MonoBehaviour
    {
        public static EpisodeSelectUI Instance { get; private set; }

        public bool isVisible = false;
        private List<EpisodeData> episodes = new List<EpisodeData>();
        private Vector2 scrollPos;

        private void Awake()
        {
            if (Instance == null) Instance = this;
            else Destroy(gameObject);
        }

        private void Start()
        {
            if (LevelParser.Instance == null)
            {
                gameObject.AddComponent<LevelParser>();
            }
            episodes = LevelParser.Instance.LoadEpisodes();
        }

        public void Show()
        {
            isVisible = true;
        }

        public void Hide()
        {
            isVisible = false;
        }

        private void OnGUI()
        {
            if (!isVisible) return;

            GUI.skin.label.fontSize = 24;
            GUI.skin.button.fontSize = 20;

            GUI.Box(new Rect(50, 50, Screen.width - 100, Screen.height - 100), "SELECT EPISODE");

            scrollPos = GUI.BeginScrollView(
                new Rect(70, 100, Screen.width - 140, Screen.height - 180),
                scrollPos,
                new Rect(0, 0, Screen.width - 180, episodes.Count * 65 + 20)
            );

            for (int i = 0; i < episodes.Count; i++)
            {
                var ep = episodes[i];
                string label = $"{i + 1}. {ep.name} ({ep.levels.Count} Levels)";
                if (GUI.Button(new Rect(10, i * 65, Screen.width - 200, 55), label))
                {
                    Hide();
                    if (LevelSelectUI.Instance != null)
                    {
                        LevelSelectUI.Instance.ShowEpisode(ep);
                    }
                }
            }

            GUI.EndScrollView();

            if (GUI.Button(new Rect(Screen.width - 170, 60, 100, 35), "CLOSE"))
            {
                Hide();
            }
        }
    }
}
