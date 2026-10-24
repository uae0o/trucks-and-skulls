using UnityEngine;

namespace TrucksAndSkulls
{
    [RequireComponent(typeof(Rigidbody2D))]
    public class TruckProjectile : MonoBehaviour
    {
        public TruckType truckType = TruckType.Bomber;
        public bool hasLaunched = false;
        public bool abilityUsed = false;

        private Rigidbody2D rb;
        private float launchTime;
        private bool isSettled = false;
        private float restTimer = 0f;

        private void Awake()
        {
            rb = GetComponent<Rigidbody2D>();
            gameObject.tag = "Player";
        }

        public void Launch(Vector2 force, TruckType type)
        {
            truckType = type;
            hasLaunched = true;
            launchTime = Time.time;
            rb.bodyType = RigidbodyType2D.Dynamic;

            ApplyTruckStats();
            rb.AddForce(force, ForceMode2D.Impulse);
        }

        private void ApplyTruckStats()
        {
            switch (truckType)
            {
                case TruckType.Bomber:
                    rb.mass = 5f;
                    break;
                case TruckType.Bus:
                    rb.mass = 4.5f;
                    break;
                case TruckType.CrotchRocket:
                    rb.mass = 2f;
                    break;
                case TruckType.Dart:
                    rb.mass = 1.5f;
                    rb.gravityScale = 0.6f;
                    break;
                case TruckType.Doomstone:
                    rb.mass = 8f;
                    break;
                case TruckType.MIRV:
                    rb.mass = 3f;
                    break;
            }
        }

        private void Update()
        {
            if (!hasLaunched || isSettled) return;

            // Trigger mid-air special ability on tap/click
            if (Input.GetMouseButtonDown(0) && !abilityUsed && (Time.time - launchTime > 0.2f))
            {
                TriggerAbility();
            }

            // Check if truck has settled or stopped
            if (rb.velocity.magnitude < 0.2f && (Time.time - launchTime > 2.0f))
            {
                restTimer += Time.deltaTime;
                if (restTimer > 1.5f)
                {
                    OnSettled();
                }
            }
            else
            {
                restTimer = 0f;
            }

            // Timeout fallback
            if (Time.time - launchTime > 12.0f)
            {
                OnSettled();
            }
        }

        public void TriggerAbility()
        {
            if (abilityUsed) return;
            abilityUsed = true;

            switch (truckType)
            {
                case TruckType.CrotchRocket:
                    // Nitro boost in current direction
                    rb.velocity = rb.velocity.normalized * (rb.velocity.magnitude * 2.2f + 10f);
                    break;

                case TruckType.Bomber:
                    // Mid-air bomb drop
                    rb.AddForce(Vector2.down * 400f);
                    break;

                case TruckType.MIRV:
                    // Split into 3
                    SplitMIRV();
                    break;
            }
        }

        private void SplitMIRV()
        {
            Vector2 baseVel = rb.velocity;
            for (int i = -1; i <= 1; i += 2)
            {
                GameObject clone = Instantiate(gameObject, transform.position + new Vector3(0, i * 0.4f, 0), transform.rotation);
                TruckProjectile cloneProj = clone.GetComponent<TruckProjectile>();
                cloneProj.hasLaunched = true;
                cloneProj.abilityUsed = true;
                Rigidbody2D cloneRb = clone.GetComponent<Rigidbody2D>();
                cloneRb.velocity = Quaternion.Euler(0, 0, i * 15f) * baseVel;
                clone.transform.localScale = transform.localScale * 0.75f;
            }
        }

        private void OnCollisionEnter2D(Collision2D collision)
        {
            if (truckType == TruckType.Bomber && !abilityUsed)
            {
                abilityUsed = true;
                Explode();
            }
        }

        private void Explode()
        {
            float radius = 4.0f;
            Collider2D[] hits = Physics2D.OverlapCircleAll(transform.position, radius);
            foreach (var h in hits)
            {
                StructurePart p = h.GetComponent<StructurePart>();
                if (p != null) p.TakeDamage(250f);

                Rigidbody2D hitRb = h.GetComponent<Rigidbody2D>();
                if (hitRb != null && hitRb.bodyType == RigidbodyType2D.Dynamic)
                {
                    Vector2 dir = (h.transform.position - transform.position).normalized;
                    hitRb.AddForce(dir * 600f);
                }
            }
        }

        private void OnSettled()
        {
            if (isSettled) return;
            isSettled = true;

            if (GameManager.Instance != null)
            {
                GameManager.Instance.OnTruckSettled();
            }

            Destroy(gameObject, 1.0f);
        }
    }
}
