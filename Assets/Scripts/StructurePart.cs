using UnityEngine;

namespace TrucksAndSkulls
{
    [RequireComponent(typeof(Rigidbody2D))]
    public class StructurePart : MonoBehaviour
    {
        public string partName;
        public MaterialType materialType = MaterialType.Wood;
        public float maxHealth = 100f;
        public float currentHealth = 100f;
        public bool isSkull = false;
        public bool isExplosive = false;
        public int scoreValue = 100;

        private Rigidbody2D rb;
        private SpriteRenderer spriteRenderer;
        private bool isDestroyed = false;

        private void Awake()
        {
            rb = GetComponent<Rigidbody2D>();
            spriteRenderer = GetComponent<SpriteRenderer>();
        }

        public void Initialize(string name, MaterialType mat, float hp, bool skull, bool explosive, int score)
        {
            partName = name;
            materialType = mat;
            maxHealth = hp;
            currentHealth = hp;
            isSkull = skull;
            isExplosive = explosive;
            scoreValue = score;

            if (isSkull && GameManager.Instance != null)
            {
                GameManager.Instance.RegisterSkull(this);
            }
        }

        private void OnCollisionEnter2D(Collision2D collision)
        {
            if (isDestroyed || materialType == MaterialType.Indestructium || materialType == MaterialType.Ground)
                return;

            float relativeVelocity = collision.relativeVelocity.magnitude;
            if (relativeVelocity < 1.5f) return;

            float damage = relativeVelocity * 10f;
            if (collision.gameObject.CompareTag("Player"))
            {
                damage *= 2.5f;
            }

            TakeDamage(damage);
        }

        public void TakeDamage(float amount)
        {
            if (isDestroyed || materialType == MaterialType.Indestructium || materialType == MaterialType.Ground)
                return;

            currentHealth -= amount;

            if (spriteRenderer != null)
            {
                float t = Mathf.Clamp01(currentHealth / maxHealth);
                spriteRenderer.color = Color.Lerp(new Color(0.5f, 0.5f, 0.5f, 1f), Color.white, t);
            }

            if (currentHealth <= 0f)
            {
                Die();
            }
        }

        private void Die()
        {
            if (isDestroyed) return;
            isDestroyed = true;

            if (isExplosive)
            {
                TriggerExplosion();
            }

            if (isSkull && GameManager.Instance != null)
            {
                GameManager.Instance.OnSkullDestroyed(this);
            }
            else if (GameManager.Instance != null)
            {
                GameManager.Instance.AddScore(scoreValue);
            }

            Destroy(gameObject);
        }

        private void TriggerExplosion()
        {
            float radius = 3.5f;
            float force = 800f;
            Collider2D[] colliders = Physics2D.OverlapCircleAll(transform.position, radius);

            foreach (Collider2D hit in colliders)
            {
                if (hit.gameObject == gameObject) continue;

                StructurePart part = hit.GetComponent<StructurePart>();
                if (part != null)
                {
                    part.TakeDamage(300f);
                }

                Rigidbody2D hitRb = hit.GetComponent<Rigidbody2D>();
                if (hitRb != null && hitRb.bodyType == RigidbodyType2D.Dynamic)
                {
                    Vector2 dir = (hit.transform.position - transform.position);
                    float dist = dir.magnitude;
                    float power = 1f - Mathf.Clamp01(dist / radius);
                    hitRb.AddForce(dir.normalized * force * power);
                }
            }
        }
    }
}
