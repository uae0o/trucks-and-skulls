using System;
using System.Collections.Generic;
using UnityEngine;

namespace TrucksAndSkulls
{
    [Serializable]
    public class LevelData
    {
        public string file;
        public string name;
        public string theme;
        public float width;
        public float height;
        public float launcherX;
        public float launcherY;
        public List<string> projectiles = new List<string>();
        public List<PartData> parts = new List<PartData>();
    }

    [Serializable]
    public class PartData
    {
        public string name;
        public float x;
        public float y;
        public float angle;
        public bool hinged;
    }

    [Serializable]
    public class EpisodeData
    {
        public string name;
        public List<string> levels = new List<string>();
        public string background;
        public string thumbnail;
    }

    [Serializable]
    public class LevelIndexItem
    {
        public string file;
        public string name;
        public string theme;
        public int partsCount;
        public int projectilesCount;
    }

    public enum MaterialType
    {
        Wood,
        Glass,
        Stone,
        Steel,
        Rubber,
        Unobtainium,
        Indestructium,
        Lava,
        Explosive,
        Skull,
        Ground
    }

    public enum TruckType
    {
        Bomber,
        Bus,
        CrotchRocket,
        Dart,
        Doomstone,
        MIRV
    }
}
