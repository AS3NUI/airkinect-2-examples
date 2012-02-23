package com.as3nui.nativeExtensions.air.kinect.examples.pointCloud {
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.data.PointCloudRegion;

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

	public class PointCloudRenderer extends Sprite {

		private var _explicitWidth:uint;

		public function get explicitWidth():uint {
			return _explicitWidth;
		}

		private var _explicitHeight:uint;

		public function get explicitHeight():uint {
			return _explicitHeight;
		}

		private var _pointCloudImage:Bitmap;
		private var _includeRGB:Boolean;

		private var _buffer:Vector.<uint>;
		private var _focalLength:Number;
		private var _matrix:Matrix3D = new Matrix3D();
		private var _targetZ:Number = 0;

		private var depthPoints:ByteArray;
		private var regions:Vector.<PointCloudRegion>;
		private var regionRenderers:Vector.<RegionRenderer>;

		private var stageRef:Stage;
		private var regionRendererContainer:Sprite;
		private var _maxDepth:uint;

		public function PointCloudRenderer(settings:KinectSettings, maxDepth:uint = 2048) {
			_maxDepth = maxDepth;
			_explicitWidth = settings.pointCloudResolution.x;
			_explicitHeight = settings.pointCloudResolution.y;
			_includeRGB = settings.pointCloudIncludeRGB;

			_buffer = new Vector.<uint>(_explicitWidth * _explicitHeight, true);

			var perspectiveProjection:PerspectiveProjection = new PerspectiveProjection();
			perspectiveProjection.fieldOfView = 60.0;
			_focalLength = perspectiveProjection.focalLength;

			_pointCloudImage = new Bitmap(new BitmapData(_explicitWidth, _explicitHeight, true, 0xffff0000));
			addChild(_pointCloudImage);

			regionRendererContainer = new Sprite();
			addChild(regionRendererContainer);

			regionRenderers = new Vector.<RegionRenderer>();

			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler, false, 0, true);
		}

		protected function addedToStageHandler(event:Event):void {
			stageRef = stage;
			stageRef.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler, false, 0, true);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}

		protected function mouseWheelHandler(event:MouseEvent):void {
			_targetZ -= event.shiftKey ? event.delta * 2 : event.delta;
		}

		protected function removedFromStageHandler(event:Event):void {
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stageRef.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
		}

		private function enterFrameHandler(event:Event):void {
			redraw();
		}

		/**
		 * Drawing code adapter form Joa-ebert
		 * http://blog.joa-ebert.com/2009/04/03/massive-amounts-of-3d-particles-without-alchemy-and-pixelbender/
		 */
		private function redraw():void {
			if (stageRef == null || depthPoints == null) return;
			var targetX:Number = ((( mouseX / _explicitWidth) - .5) * 2) * 90;
			var targetY:Number = ((( mouseY / _explicitHeight) - .5) * 2) * -90;

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

			var bufferWidth:int = _explicitWidth;
			var bufferMax:int = _buffer.length;
			var bufferMin:int = -1;
			var bufferIndex:int;
			var buffer:Vector.<uint> = _buffer;

			var halfWidth:int = _explicitWidth * .5;
			var halfHeight:int = _explicitHeight * .5;
			var cx:Number = _explicitWidth * .5;
			var cy:Number = _explicitHeight * .5;
			var minZ:Number = 0.0;

			var n:int = bufferMax;
			while (--n > -1) buffer[ n ] = 0xff000000;

			var zAbs:Number;

			depthPoints.position = 0;

			if (_includeRGB) {
				var r:uint;
				var g:uint;
				var b:uint;
				while (depthPoints.bytesAvailable >= 12) {
					x = depthPoints.readShort();
					y = depthPoints.readShort();
					z = depthPoints.readShort();

					r = depthPoints.readShort();
					g = depthPoints.readShort();
					b = depthPoints.readShort();

					x -= halfWidth;
					y -= halfHeight;

					if (z < 1) z = 1;
					if (z > _maxDepth) z = _maxDepth;
					z -= (_maxDepth / 2);

					pz = _focalLength + x * p02 + y * p12 + z * p22 + p32;

					if (minZ < pz && z > -1000) {
						xi = int(( w = _focalLength / pz ) * ( x * p00 + y * p10 + z * p20 ) + cx);
						if (xi < 0) continue;
						if (xi > bufferWidth) continue;

						yi = int(w * ( x * p01 + y * p11 + z * p21 ) + cy);

						if (bufferMin < ( bufferIndex = int(xi + int(yi * bufferWidth)) ) && bufferIndex < bufferMax) {
							//zAbs = Math.abs((1 - Math.abs((z + 1024) / 2047)) * 255);
							buffer[ bufferIndex ] = 0xff << 24 | r << 16 | g << 8 | b;
						}
					}
				}
			}
			else {

				while (depthPoints.bytesAvailable >= 6) {
					x = depthPoints.readShort();
					y = depthPoints.readShort();
					z = depthPoints.readShort();

					x -= halfWidth;
					y -= halfHeight;

					if (z < 1) z = 1;
					if (z > _maxDepth) z = _maxDepth;
					z -= (_maxDepth / 2);

					pz = _focalLength + x * p02 + y * p12 + z * p22 + p32;

					if (minZ < pz && z > -1000) {
						xi = int(( w = _focalLength / pz ) * ( x * p00 + y * p10 + z * p20 ) + cx);
						if (xi < 0) continue;
						if (xi > bufferWidth) continue;

						yi = int(w * ( x * p01 + y * p11 + z * p21 ) + cy);

						if (bufferMin < ( bufferIndex = int(xi + int(yi * bufferWidth)) ) && bufferIndex < bufferMax) {
							zAbs = Math.abs((1 - Math.abs((z + 1024) / 2047)) * 255);
							buffer[ bufferIndex ] = 0xff << 24 | zAbs << 16 | zAbs << 8 | zAbs;
						}
					}
				}
			}

			_pointCloudImage.bitmapData.lock();
			_pointCloudImage.bitmapData.setVector(_pointCloudImage.bitmapData.rect, buffer);
			_pointCloudImage.bitmapData.unlock(_pointCloudImage.bitmapData.rect);

			for each(var regionRenderer:RegionRenderer in regionRenderers) {
				regionRenderer.render(_matrix, _focalLength);
			}
		}

		public function updatePoints(depthPoints:ByteArray):void {
			this.depthPoints = depthPoints;
		}

		public function updateRegions(regions:Vector.<PointCloudRegion>):void {
			this.regions = regions;
			regionRenderers.length = 0;
			regionRendererContainer.removeChildren();
			for each(var region:PointCloudRegion in regions) {
				var renderer:RegionRenderer = new RegionRenderer(this, region);
				renderer.x = _explicitWidth * .5;
				renderer.y = _explicitHeight * .5;
				regionRenderers.push(renderer);
				regionRendererContainer.addChild(renderer);
			}
		}

		public function get includeRGB():Boolean {
			return _includeRGB;
		}

		public function set includeRGB(value:Boolean):void {
			_includeRGB = value;
		}
	}
}

import com.as3nui.nativeExtensions.air.kinect.data.PointCloudRegion;
import com.as3nui.nativeExtensions.air.kinect.examples.pointCloud.PointCloudRenderer;

import flash.display.Sprite;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Vector3D;

/**
 * Draws a 3D region on the screen
 * http://blog.andreanaya.com/lang/en/2009/04/matrix3d-101/
 */
internal class RegionRenderer extends Sprite {

	private var p0:Vector3D;
	private var p1:Vector3D;
	private var p2:Vector3D;
	private var p3:Vector3D;
	private var p4:Vector3D;
	private var p5:Vector3D;
	private var p6:Vector3D;
	private var p7:Vector3D;

	private var pointCloudRenderer:PointCloudRenderer;
	private var region:PointCloudRegion;
	private var localMatrix:Matrix3D;

	public function RegionRenderer(pointCloudRenderer:PointCloudRenderer, region:PointCloudRegion) {
		this.pointCloudRenderer = pointCloudRenderer;
		this.region = region;
		var halfWidth:Number = region.width * .5;
		var halfHeight:Number = region.height * .5;
		var halfDepth:Number = region.depth * .5;
		//set the points from the region
		localMatrix = new Matrix3D();
		var z:Number = region.z;
		if (z < 1) z = 1;
		if (z > 2047) z = 2047;
		z -= 1024;

		localMatrix.appendTranslation(region.x - (pointCloudRenderer.explicitWidth * .5), region.y - (pointCloudRenderer.explicitHeight * .5), z);

		p0 = new Vector3D(-halfWidth, -halfHeight, -halfDepth);
		p1 = new Vector3D(halfWidth, -halfHeight, -halfDepth);
		p2 = new Vector3D(halfWidth, halfHeight, -halfDepth);
		p3 = new Vector3D(-halfWidth, halfHeight, -halfDepth);
		p4 = new Vector3D(-halfWidth, -halfHeight, halfDepth);
		p5 = new Vector3D(halfWidth, -halfHeight, halfDepth);
		p6 = new Vector3D(halfWidth, halfHeight, halfDepth);
		p7 = new Vector3D(-halfWidth, halfHeight, halfDepth);
	}

	public function render(matrix:Matrix3D, focalLength:Number):void {
		var m:Matrix3D = localMatrix.clone();
		m.append(matrix);

		var point0:Point = getPerspective(m.transformVector(p0), focalLength);
		var point1:Point = getPerspective(m.transformVector(p1), focalLength);
		var point2:Point = getPerspective(m.transformVector(p2), focalLength);
		var point3:Point = getPerspective(m.transformVector(p3), focalLength);
		var point4:Point = getPerspective(m.transformVector(p4), focalLength);
		var point5:Point = getPerspective(m.transformVector(p5), focalLength);
		var point6:Point = getPerspective(m.transformVector(p6), focalLength);
		var point7:Point = getPerspective(m.transformVector(p7), focalLength);

		graphics.clear();
		graphics.lineStyle(2, 0xFF0000);

		if (region.numPoints > 10) {
			graphics.beginFill(0xFF0000, 0.5);
		}

		graphics.moveTo(point0.x, point0.y);
		graphics.lineTo(point1.x, point1.y);
		graphics.lineTo(point2.x, point2.y);
		graphics.lineTo(point3.x, point3.y);
		graphics.lineTo(point0.x, point0.y);

		graphics.endFill();

		if (region.numPoints > 10) {
			graphics.beginFill(0xFF0000, 0.5);
		}

		graphics.moveTo(point4.x, point4.y);
		graphics.lineTo(point5.x, point5.y);
		graphics.lineTo(point6.x, point6.y);
		graphics.lineTo(point7.x, point7.y);
		graphics.lineTo(point4.x, point4.y);

		graphics.endFill();

		graphics.moveTo(point0.x, point0.y);
		graphics.lineTo(point4.x, point4.y);

		graphics.moveTo(point1.x, point1.y);
		graphics.lineTo(point5.x, point5.y);

		graphics.moveTo(point2.x, point2.y);
		graphics.lineTo(point6.x, point6.y);

		graphics.moveTo(point3.x, point3.y);
		graphics.lineTo(point7.x, point7.y);
	}

	private function getPerspective(vector:Vector3D, focalLength:Number):Point {
		var scaleFactor:Number = focalLength / (focalLength + vector.z);

		var point:Point = new Point();
		point.x = vector.x * scaleFactor;
		point.y = vector.y * scaleFactor;

		return point;
	}

}