using System.Collections.Generic;
using UnityEngine;

namespace TrucksAndSkulls
{
    public class GamePhysics : MonoBehaviour
    {
        public static GamePhysics Instance { get; private set; }

        public const float SCALE = 0.02f; // 1 level pt = 0.02 Unity units

        [Header("Physics Materials")]
        public PhysicsMaterial2D woodMat;
        public PhysicsMaterial2D glassMat;
        public PhysicsMaterial2D stoneMat;
        public PhysicsMaterial2D steelMat;
        public PhysicsMaterial2D rubberMat;
        public PhysicsMaterial2D unobtainiumMat;
        public PhysicsMaterial2D groundMat;

        private GameObject levelContainer;

        private void Awake()
        {
            if (Instance == null) Instance = this;
            else Destroy(gameObject);
            CreateDefaultPhysicsMaterials();
        }

        private void CreateDefaultPhysicsMaterials()
        {
            woodMat = new PhysicsMaterial2D("Wood") { friction = 0.5f, bounciness = 0.2f };
            glassMat = new PhysicsMaterial2D("Glass") { friction = 0.3f, bounciness = 0.1f };
            stoneMat = new PhysicsMaterial2D("Stone") { friction = 0.6f, bounciness = 0.1f };
            steelMat = new PhysicsMaterial2D("Steel") { friction = 0.4f, bounciness = 0.3f };
            rubberMat = new PhysicsMaterial2D("Rubber") { friction = 0.8f, bounciness = 0.9f };
            unobtainiumMat = new PhysicsMaterial2D("Unobtainium") { friction = 0.3f, bounciness = 0.2f };
            groundMat = new PhysicsMaterial2D("Ground") { friction = 0.7f, bounciness = 0.0f };
        }

        public void ClearLevel()
        {
            if (levelContainer != null)
            {
                Destroy(levelContainer);
            }
            levelContainer = new GameObject("Level_Container");
        }

        public void SpawnLevel(LevelData level)
        {
            ClearLevel();

            // Spawn ground box
            CreateGround(level.width, level.height);

            foreach (var part in level.parts)
            {
                SpawnPart(part);
            }
        }

        private void CreateGround(float width, float height)
        {
            GameObject ground = new GameObject("Ground");
            ground.transform.SetParent(levelContainer.transform);
            ground.transform.position = new Vector2(0f, -(height * 0.5f) * SCALE);

            BoxCollider2D col = ground.AddComponent<BoxCollider2D>();
            col.size = new Vector2((width + 400f) * SCALE, 2f);
            col.sharedMaterial = groundMat;

            Rigidbody2D rb = ground.AddComponent<Rigidbody2D>();
            rb.bodyType = RigidbodyType2D.Static;

            StructurePart sp = ground.AddComponent<StructurePart>();
            sp.Initialize("Ground", MaterialType.Ground, 999999f, false, false, 0);
        }

        public GameObject SpawnPart(PartData part)
        {
            GameObject obj = new GameObject(part.name);
            obj.transform.SetParent(levelContainer.transform);
            obj.transform.position = new Vector2(part.x * SCALE, part.y * SCALE);
            obj.transform.rotation = Quaternion.Euler(0, 0, part.angle);

            MaterialType mat = DetermineMaterial(part.name);
            Vector2 size = DetermineSize(part.name);
            bool isCircle = part.name.Contains("Circle");
            bool isTriangle = part.name.Contains("Triangle");
            bool isSkull = part.name.Contains("Skull");
            bool isExplosive = part.name.Contains("Boiler") || part.name.Contains("Dynamite") || part.name.Contains("Barrel");

            Rigidbody2D rb = obj.AddComponent<Rigidbody2D>();
            if (part.name == "StructurePart_GroundBox" || mat == MaterialType.Ground)
            {
                rb.bodyType = RigidbodyType2D.Static;
            }
            else
            {
                rb.bodyType = RigidbodyType2D.Dynamic;
                rb.mass = GetMass(mat, size);
            }

            Collider2D collider;
            if (isCircle)
            {
                CircleCollider2D cc = obj.AddComponent<CircleCollider2D>();
                cc.radius = (size.x * 0.5f) * SCALE;
                collider = cc;
            }
            else if (isTriangle)
            {
                PolygonCollider2D pc = obj.AddComponent<PolygonCollider2D>();
                float w = size.x * 0.5f * SCALE;
                float h = size.y * 0.5f * SCALE;
                pc.points = new Vector2[] { new Vector2(-w, -h), new Vector2(w, -h), new Vector2(-w, h) };
                collider = pc;
            }
            else
            {
                BoxCollider2D bc = obj.AddComponent<BoxCollider2D>();
                bc.size = new Vector2(size.x * SCALE, size.y * SCALE);
                collider = bc;
            }

            collider.sharedMaterial = GetPhysicsMaterial(mat);

            SpriteRenderer sr = obj.AddComponent<SpriteRenderer>();
            sr.color = GetMaterialColor(mat);
            sr.sprite = CreateDummySprite();

            StructurePart sp = obj.AddComponent<StructurePart>();
            sp.Initialize(part.name, mat, GetMaxHealth(mat), isSkull, isExplosive, isSkull ? 1000 : 100);

            return obj;
        }

        private Sprite CreateDummySprite()
        {
            Texture2D tex = Texture2D.whiteTexture;
            return Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100f);
        }

        private MaterialType DetermineMaterial(string name)
        {
            if (name.Contains("Wood")) return MaterialType.Wood;
            if (name.Contains("Glass")) return MaterialType.Glass;
            if (name.Contains("Stone")) return MaterialType.Stone;
            if (name.Contains("Steel")) return MaterialType.Steel;
            if (name.Contains("Rubber")) return MaterialType.Rubber;
            if (name.Contains("Unobtainium")) return MaterialType.Unobtainium;
            if (name.Contains("Indestructium")) return MaterialType.Indestructium;
            if (name.Contains("Lava")) return MaterialType.Lava;
            if (name.Contains("Skull")) return MaterialType.Skull;
            if (name.Contains("Ground")) return MaterialType.Ground;
            if (name.Contains("Boiler") || name.Contains("Dynamite")) return MaterialType.Explosive;
            return MaterialType.Wood;
        }

        private Vector2 DetermineSize(string name)
        {
            if (name.Contains("GroundBox")) return new Vector2(2034, 100);
            if (name.Contains("HugeSquare") || name.Contains("HugeSuperstructure")) return new Vector2(160, 160);
            if (name.Contains("LargeSquare")) return new Vector2(100, 100);
            if (name.Contains("MediumSquare")) return new Vector2(60, 60);
            if (name.Contains("SmallSquare")) return new Vector2(34, 34);
            if (name.Contains("VeryLongBeam")) return new Vector2(240, 24);
            if (name.Contains("LongBeam")) return new Vector2(180, 24);
            if (name.Contains("LargeBeam")) return new Vector2(120, 24);
            if (name.Contains("MediumBeam")) return new Vector2(80, 24);
            if (name.Contains("SmallBeam")) return new Vector2(48, 24);
            if (name.Contains("DoubleBeam")) return new Vector2(160, 48);
            if (name.Contains("LargeCircle")) return new Vector2(90, 90);
            if (name.Contains("MediumCircle")) return new Vector2(60, 60);
            if (name.Contains("SmallCircle")) return new Vector2(34, 34);
            if (name.Contains("Skull")) return new Vector2(48, 48);
            if (name.Contains("Boiler") || name.Contains("Barrel")) return new Vector2(50, 70);
            return new Vector2(60, 60);
        }

        private float GetMass(MaterialType mat, Vector2 size)
        {
            float area = (size.x * size.y) * 0.001f;
            switch (mat)
            {
                case MaterialType.Glass: return area * 0.8f;
                case MaterialType.Wood: return area * 1.0f;
                case MaterialType.Rubber: return area * 1.2f;
                case MaterialType.Stone: return area * 2.0f;
                case MaterialType.Steel: return area * 3.0f;
                case MaterialType.Unobtainium: return area * 4.0f;
                case MaterialType.Indestructium: return area * 10.0f;
                case MaterialType.Skull: return 0.8f;
                default: return area * 1.0f;
            }
        }

        private float GetMaxHealth(MaterialType mat)
        {
            switch (mat)
            {
                case MaterialType.Glass: return 50f;
                case MaterialType.Wood: return 100f;
                case MaterialType.Rubber: return 150f;
                case MaterialType.Stone: return 220f;
                case MaterialType.Steel: return 400f;
                case MaterialType.Unobtainium: return 1000f;
                case MaterialType.Indestructium: return 999999f;
                case MaterialType.Skull: return 60f;
                case MaterialType.Explosive: return 40f;
                default: return 100f;
            }
        }

        private PhysicsMaterial2D GetPhysicsMaterial(MaterialType mat)
        {
            switch (mat)
            {
                case MaterialType.Glass: return glassMat;
                case MaterialType.Wood: return woodMat;
                case MaterialType.Stone: return stoneMat;
                case MaterialType.Steel: return steelMat;
                case MaterialType.Rubber: return rubberMat;
                case MaterialType.Unobtainium: return unobtainiumMat;
                default: return woodMat;
            }
        }

        private Color GetMaterialColor(MaterialType mat)
        {
            switch (mat)
            {
                case MaterialType.Wood: return new Color(0.75f, 0.52f, 0.32f);
                case MaterialType.Glass: return new Color(0.6f, 0.85f, 0.95f, 0.75f);
                case MaterialType.Stone: return new Color(0.55f, 0.55f, 0.55f);
                case MaterialType.Steel: return new Color(0.35f, 0.42f, 0.5f);
                case MaterialType.Rubber: return new Color(0.95f, 0.85f, 0.15f);
                case MaterialType.Unobtainium: return new Color(0.65f, 0.2f, 0.85f);
                case MaterialType.Indestructium: return new Color(0.2f, 0.2f, 0.25f);
                case MaterialType.Lava: return new Color(0.95f, 0.3f, 0.05f);
                case MaterialType.Skull: return new Color(0.95f, 0.95f, 0.85f);
                case MaterialType.Explosive: return new Color(0.85f, 0.15f, 0.15f);
                case MaterialType.Ground: return new Color(0.3f, 0.25f, 0.2f);
                default: return Color.gray;
            }
        }
    }
}
