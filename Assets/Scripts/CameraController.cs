using UnityEngine;

namespace TrucksAndSkulls
{
    public class CameraController : MonoBehaviour
    {
        public static CameraController Instance { get; private set; }

        public Transform target;
        public float smoothSpeed = 4.0f;
        public Vector2 minBounds = new Vector2(-25f, -10f);
        public Vector2 maxBounds = new Vector2(25f, 15f);

        private Camera cam;
        private Vector3 defaultPosition;
        private bool isFollowing = false;
        private Vector3 dragOrigin;

        private void Awake()
        {
            if (Instance == null) Instance = this;
            else Destroy(gameObject);
            cam = GetComponent<Camera>();
            if (cam == null) cam = Camera.main;
        }

        public void SetLevelBounds(float width, float height, Vector2 launcherPos)
        {
            float halfW = width * GamePhysics.SCALE * 0.5f;
            float halfH = height * GamePhysics.SCALE * 0.5f;
            minBounds = new Vector2(-halfW - 5f, -halfH);
            maxBounds = new Vector2(halfW + 5f, halfH + 8f);

            defaultPosition = new Vector3(launcherPos.x + 6f, launcherPos.y + 2f, -10f);
            ResetToLauncher();
        }

        public void FollowTarget(Transform newTarget)
        {
            target = newTarget;
            isFollowing = true;
        }

        public void StopFollowing()
        {
            isFollowing = false;
            target = null;
        }

        public void ResetToLauncher()
        {
            StopFollowing();
            transform.position = defaultPosition;
        }

        private void LateUpdate()
        {
            if (isFollowing && target != null)
            {
                Vector3 desired = new Vector3(target.position.x + 2f, target.position.y + 1f, -10f);
                desired.x = Mathf.Clamp(desired.x, minBounds.x, maxBounds.x);
                desired.y = Mathf.Clamp(desired.y, minBounds.y, maxBounds.y);
                transform.position = Vector3.Lerp(transform.position, desired, smoothSpeed * Time.deltaTime);
                return;
            }

            HandleTouchAndMousePanning();
        }

        private void HandleTouchAndMousePanning()
        {
            // Mobile pinch to zoom
            if (Input.touchCount == 2)
            {
                Touch t0 = Input.GetTouch(0);
                Touch t1 = Input.GetTouch(1);
                Vector2 t0Prev = t0.position - t0.deltaPosition;
                Vector2 t1Prev = t1.position - t1.deltaPosition;
                float prevMagnitude = (t0Prev - t1Prev).magnitude;
                float currentMagnitude = (t0.position - t1.position).magnitude;
                float diff = currentMagnitude - prevMagnitude;

                cam.orthographicSize = Mathf.Clamp(cam.orthographicSize - diff * 0.01f, 4f, 16f);
                return;
            }

            // Mouse wheel zoom
            float scroll = Input.GetAxis("Mouse ScrollWheel");
            if (Mathf.Abs(scroll) > 0.01f)
            {
                cam.orthographicSize = Mathf.Clamp(cam.orthographicSize - scroll * 4f, 4f, 16f);
            }

            // Pan with right mouse or single touch (outside drag)
            if (Input.GetMouseButtonDown(1) || (Input.touchCount == 1 && Input.GetTouch(0).phase == TouchPhase.Began && Input.GetTouch(0).position.x > Screen.width * 0.4f))
            {
                dragOrigin = cam.ScreenToWorldPoint(Input.mousePosition);
            }

            if (Input.GetMouseButton(1) || (Input.touchCount == 1 && Input.GetTouch(0).phase == TouchPhase.Moved && Input.GetTouch(0).position.x > Screen.width * 0.4f))
            {
                Vector3 diff = dragOrigin - cam.ScreenToWorldPoint(Input.mousePosition);
                Vector3 pos = transform.position + diff;
                pos.x = Mathf.Clamp(pos.x, minBounds.x, maxBounds.x);
                pos.y = Mathf.Clamp(pos.y, minBounds.y, maxBounds.y);
                transform.position = pos;
            }
        }
    }
}
