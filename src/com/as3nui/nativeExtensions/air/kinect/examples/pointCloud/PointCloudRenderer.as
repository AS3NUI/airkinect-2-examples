package com.as3nui.nativeExtensions.air.kinect.examples.pointCloud
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	public class PointCloudRenderer extends Sprite
	{
		
		private var _pointCloudImage:Bitmap;
		
		private var _buffer: Vector.<uint> = new Vector.<uint>( 320 * 240, true );
		private var _focalLength: Number;
		private var _matrix:Matrix3D = new Matrix3D();
		private var _targetZ:Number = 0;
		private var depthPoints:ByteArray;
		
		private var stageRef:Stage;
		
		public function PointCloudRenderer()
		{
			var perspectiveProjection:PerspectiveProjection = new PerspectiveProjection( );
			perspectiveProjection.fieldOfView = 60.0;
			_focalLength = perspectiveProjection.focalLength;
			
			_pointCloudImage = new Bitmap(new BitmapData(320, 240, true, 0xffff0000));
			addChild(_pointCloudImage);
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler, false, 0, true);
		}
		
		protected function addedToStageHandler(event:Event):void
		{
			stageRef = stage;
			stageRef.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler, false, 0, true);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}
		
		protected function mouseWheelHandler(event:MouseEvent):void
		{
			trace("mouse wheel");
			_targetZ -= event.shiftKey ? event.delta *2 : event.delta;
		}
		
		protected function removedFromStageHandler(event:Event):void
		{
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stageRef.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
		}
		
		private function enterFrameHandler(event:Event):void
		{
			redraw();
		}
		
		/**
		 * Drawing code adapter form Joa-ebert
		 * http://blog.joa-ebert.com/2009/04/03/massive-amounts-of-3d-particles-without-alchemy-and-pixelbender/
		 */
		private function redraw():void
		{
			if(stageRef == null || depthPoints == null) return;
			var targetX:Number = ((( mouseX / stageRef.stageWidth) - .5) * 2) * 180;
			var targetY:Number = ((( mouseY / stageRef.stageHeight) - .5) * 2) * 180;
			
			_matrix.identity();
			_matrix.appendRotation(targetX, Vector3D.Y_AXIS);
			_matrix.appendRotation(targetY, Vector3D.X_AXIS);
			_matrix.appendTranslation(0.0, 0.0, _targetZ);
			
			var x:Number;
			var y:Number;
			var z:Number;
			var w:Number;
			
			var pz:Number;
			
			var xi:int;
			var yi:int;
			
			var p00:Number = _matrix.rawData[ 0x0 ];
			var p01:Number = _matrix.rawData[ 0x1 ];
			var p02:Number = _matrix.rawData[ 0x2 ];
			var p10:Number = _matrix.rawData[ 0x4 ];
			var p11:Number = _matrix.rawData[ 0x5 ];
			var p12:Number = _matrix.rawData[ 0x6 ];
			var p20:Number = _matrix.rawData[ 0x8 ];
			var p21:Number = _matrix.rawData[ 0x9 ];
			var p22:Number = _matrix.rawData[ 0xa ];
			var p32:Number = _matrix.rawData[ 0xe ];
			
			var bufferWidth:int = 320;
			var bufferMax:int = _buffer.length;
			var bufferMin:int = -1;
			var bufferIndex:int;
			var buffer:Vector.<uint> = _buffer;
			
			var cx:Number = 160.0;
			var cy:Number = 120.0;
			var minZ:Number = 0.0;
			
			var n:int = bufferMax;
			while (--n > -1) buffer[ n ] = 0xff000000;
			
			var r:Number;
			
			depthPoints.position = 0;
			while (depthPoints.bytesAvailable) {
				x = depthPoints.readShort();
				x -= 160;
				
				y = depthPoints.readShort();
				y -= 120;
				
				z = depthPoints.readShort();
				if (z < 1) z = 1;
				if (z > 2047) z = 2047;
				z -= 1024;
				
				pz = _focalLength + x * p02 + y * p12 + z * p22 + p32;
				
				if (minZ < pz) {
					xi = int(( w = _focalLength / pz ) * ( x * p00 + y * p10 + z * p20 ) + cx);
					if (xi < 0) continue;
					if (xi > bufferWidth) continue;
					
					yi = int(w * ( x * p01 + y * p11 + z * p21 ) + cy);
					
					if (bufferMin < ( bufferIndex = int(xi + int(yi * bufferWidth)) ) && bufferIndex < bufferMax) {
						r = Math.abs((1 - Math.abs((z + 1024) / 2047)) * 255);
						buffer[ bufferIndex ] = 0xff << 24 | r << 16 | r << 8 | r;
					}
				}
			}
			
			_pointCloudImage.bitmapData.lock();
			_pointCloudImage.bitmapData.setVector(_pointCloudImage.bitmapData.rect, buffer);
			_pointCloudImage.bitmapData.unlock(_pointCloudImage.bitmapData.rect);
		}
		
		
		public function updatePoints(depthPoints:ByteArray):void
		{
			this.depthPoints = depthPoints;
		}
	}
}