package jiglib.plugin.away3dlite
{
	import flash.display.BitmapData;

    public class TerrainData
    {
		public var heightMap:BitmapData;
		public var maxHeight:Number;
    	
        public function TerrainData(heightMap:BitmapData, maxHeight:Number = 100)
        {
			this.heightMap = heightMap;
			this.maxHeight = maxHeight;
        }
    }
}