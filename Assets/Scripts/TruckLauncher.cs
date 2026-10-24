using System.Collections.Generic;
using UnityEngine;

namespace TrucksAndSkulls
{
    public class TruckLauncher : MonoBehaviour
    {
        public static TruckLauncher Instance { get; private set; }

        public Transform launchPoint;
        public LineRenderer trajectoryLine;
        public float maxDragDistance = 3.5f;
        public float launchForceMultiplier = 16f;

        private Vector2 launcherPosition;
        private bool isDragging = false;
        private Vector2 dragCurrentPos;
        private GameObject currentTruckInstance;
        private TruckType currentTruckType = TruckType.Bomber;

        private void Awake()
        {
            if (Instance == null) Instance = this;
            else Destroy(gameObject);

            if (trajectoryLine == null)
            {
                trajectoryLine = gameObject.AddComponent<LineRenderer>();
                trajectoryLine.startWidth = 0.08f;
                trajectoryLine.endWidth = 0.02f;
                trajectoryLine.positionCount = 0;
                trajectoryLine.material = new Material(Shader.Find("Sprites/Default"));
                trajectoryLine.startColor = new Color(1f, 0.8f, 0.2f, 0.8f);
                trajectoryLine.endColor = new Color(1f, 0.2f, 0.1f, 0.2f);
            }
        }

        public void SetupLauncher(Vector2 position)
        {
            launcherPosition = position;
            transform.position = launcherPosition;
            if (launchPoint == null)
            {
                launchPoint = transform;
            }
        }

        public void PrepareNextTruck(TruckType type)
        {
            currentTruckType = type;
            if (currentTruckInstance != null)
            {
                Destroy(currentTruckInstance);
            }

            currentTruckInstance = CreateTruckGameObject(type);
            currentTruckInstance.transform.position = launcherPosition;
            Rigidbody2D rb = currentTruckInstance.GetComponent<Rigidbody2D>();
            rb.bodyType = RigidbodyType2D.Kinematic;
        }

        private GameObject CreateTruckGameObject(TruckType type)
        {
            GameObject obj = new GameObject($"Truck_{type}");
            obj.tag = "Player";

            SpriteRenderer sr = obj.AddComponent<SpriteRenderer>();
            sr.sprite = Sprite.Create(Texture2D.whiteTexture, new Rect(0, 0, 4, 4), new Vector2(0.5f, 0.5f), 100f);
            sr.color = GetTruckColor(type);

            BoxCollider2D col = obj.AddComponent<BoxCollider2D>();
            col.size = new Vector2(1.2f, 0.7f);

            Rigidbody2D rb = obj.AddComponent<Rigidbody2D>();
            rb.collisionDetectionMode = CollisionDetectionMode2D.Continuous;

            obj.AddComponent<TruckProjectile>();
            return obj;
        }

        private Color GetTruckColor(TruckType type)
        {
            switch (type)
            {
                case TruckType.Bomber: return new Color(0.9f, 0.2f, 0.2f);
                case TruckType.Bus: return new Color(0.95f, 0.75f, 0.1f);
                case TruckType.CrotchRocket: return new Color(0.1f, 0.7f, 0.95f);
                case TruckType.Dart: return new Color(0.2f, 0.9f, 0.3f);
                case TruckType.Doomstone: return new Color(0.4f, 0.1f, 0.6f);
                case TruckType.MIRV: return new Color(0.95f, 0.4f, 0.1f);
                default: return Color.red;
            }
        }

        private void Update()
        {
            if (GameManager.Instance != null && GameManager.Instance.IsGameOver()) return;
            if (currentTruckInstance == null) return;

            Vector2 mouseWorld = Camera.main.ScreenToWorldPoint(Input.mousePosition);

            if (Input.GetMouseButtonDown(0))
            {
                float dist = Vector2.Distance(mouseWorld, launcherPosition);
                if (dist < 2.5f)
                {
                    isDragging = true;
                }
            }

            if (isDragging)
            {
                if (Input.GetMouseButton(0))
                {
                    Vector2 pull = mouseWorld - launcherPosition;
                    if (pull.magnitude > maxDragDistance)
                    {
                        pull = pull.normalized * maxDragDistance;
                    }

                    dragCurrentPos = launcherPosition + pull;
                    currentTruckInstance.transform.position = dragCurrentPos;

                    Vector2 launchDir = (launcherPosition - dragCurrentPos);
                    float angle = Mathf.Atan2(launchDir.y, launchDir.x) * Mathf.Rad2Deg;
                    currentTruckInstance.transform.rotation = Quaternion.Euler(0, 0, angle);

                    DrawTrajectory(launchDir * launchForceMultiplier);
                }
                else if (Input.GetMouseButtonUp(0))
                {
                    isDragging = false;
                    trajectoryLine.positionCount = 0;
                    FireTruck();
                }
            }
        }

        private void DrawTrajectory(Vector2 force)
        {
            int points = 25;
            trajectoryLine.positionCount = points;
            Vector2 origin = launcherPosition;
            Vector2 vel = force / 3.0f; // estimated initial velocity

            for (int i = 0; i < points; i++)
            {
                float t = i * 0.08f;
                Vector2 pos = origin + vel * t + 0.5f * Physics2D.gravity * (t * t);
                trajectoryLine.SetPosition(i, pos);
            }
        }

        private void FireTruck()
        {
            Vector2 launchVec = (launcherPosition - dragCurrentPos) * launchForceMultiplier;
            if (launchVec.magnitude < 1.0f)
            {
                currentTruckInstance.transform.position = launcherPosition;
                return;
            }

            TruckProjectile proj = currentTruckInstance.GetComponent<TruckProjectile>();
            proj.Launch(launchVec, currentTruckType);

            if (CameraController.Instance != null)
            {
                CameraController.Instance.FollowTarget(currentTruckInstance.transform);
            }

            currentTruckInstance = null;

            if (GameManager.Instance != null)
            {
                GameManager.Instance.OnTruckFired();
            }
        }
    }
}
