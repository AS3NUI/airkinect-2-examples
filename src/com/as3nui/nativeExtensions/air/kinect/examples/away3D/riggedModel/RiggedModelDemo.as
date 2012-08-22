package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel {

import away3d.cameras.Camera3D;
import away3d.containers.Scene3D;
import away3d.containers.View3D;

import com.as3nui.nativeExtensions.air.kinect.Kinect;
import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
import com.as3nui.nativeExtensions.air.kinect.constants.DeviceState;
import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
import com.as3nui.nativeExtensions.air.kinect.data.User;
import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
import com.as3nui.nativeExtensions.air.kinect.recorder.KinectPlayer;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.filesystem.File;

public class RiggedModelDemo extends DemoBase {

    private var scene:Scene3D;
    private var camera:Camera3D;
    private var view:View3D;

    private var device:Kinect;
    private var player:KinectPlayer;

    private var rgbBitmap:Bitmap;
    private var rgbSkeletonContainer:Sprite;

    private var riggedModels:Vector.<RiggedModel>;

    override protected function startDemoImplementation():void {
        trace("[RiggedModelDemo] Start Demo");

        scene = new Scene3D();
        camera = new Camera3D();

        camera.z = 13 * -14;
        camera.y = 170 * .5;

        riggedModels = new Vector.<RiggedModel>();

        view = new View3D();
        view.antiAlias = 4;
        view.backgroundColor = 0xFFFFFF;
        view.scene = scene;
        view.camera = camera;
        addChild(view);

        rgbBitmap = new Bitmap();
        addChild(rgbBitmap);

        rgbSkeletonContainer = new Sprite();
        addChild(rgbSkeletonContainer);

        var settings:KinectSettings = new KinectSettings();
        settings.rgbEnabled = true;
        settings.rgbResolution = CameraResolution.RESOLUTION_320_240;
        settings.skeletonEnabled = true;
        settings.skeletonMirrored = true;

        player = new KinectPlayer();
        player.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
        player.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
        player.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
        player.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
        player.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);

        //simulate using a recording
        //player.playbackDirectoryUrl = File.documentsDirectory.resolvePath("export-openni").url;
        //player.start(settings);

        //use kinect when the player / simulator is not used
        if (player.state == DeviceState.STOPPED && Kinect.isSupported()) {
            device = Kinect.getDevice();

            device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
            device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
            device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
            device.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
            device.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);

            device.start(settings);
        }

        addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
    }

    protected function rgbImageUpdateHandler(event:CameraImageEvent):void {
        rgbBitmap.bitmapData = event.imageData;
    }

    protected function kinectStartedHandler(event:DeviceEvent):void {
        if (event.target == device) {
            trace("[RiggedModelDemo] Kinect started");
        }
        else {
            trace("[RiggedModelDemo] Kinect Player started");
        }
    }

    protected function kinectStoppedHandler(event:DeviceEvent):void {
        if (event.target == player) {
            trace("[RiggedModelDemo] Kinect stopped");
        }
        else {
            trace("[RiggedModelDemo] Kinect Player stopped");
        }
    }

    protected function usersWithSkeletonAddedHandler(event:UserEvent):void {
        trace("[RiggedModelDemo] User With Skeleton Added", event.users);
        for each(var user:User in event.users) {
            createRiggedModelForUser(user);
        }
    }

    private function createRiggedModelForUser(user:User):void {
        var riggedModel:RiggedModel = new RiggedModel(user);
        riggedModels.push(riggedModel);
        scene.addChild(riggedModel);
        trace("added rigged model");
    }

    protected function usersWithSkeletonRemovedHandler(event:UserEvent):void {
        trace("[RiggedModelDemo] User With Skeleton Removed", event.users);
        for each(var user:User in event.users) {
            destroyRiggedModelForUser(user);
        }
    }

    private function destroyRiggedModelForUser(user:User):void {
        var index:int = -1;
        for (var i:int = 0; i < riggedModels.length; i++) {
            if (riggedModels[i].user == user) {
                scene.removeChild(riggedModels[i]);
            }
        }
        if (index > -1)
            riggedModels.splice(index, 1);
    }

    protected function enterFrameHandler(event:Event):void {
        view.render();
        if (rgbSkeletonContainer != null) {
            rgbSkeletonContainer.graphics.clear();
            if (device != null) {
                drawUsers(device.usersWithSkeleton);
            }
            if (player != null) {
                drawUsers(player.users);
            }
        }
    }

    private function drawUsers(users:Vector.<User>):void {
        for each(var user:User in users) {
            drawRGBBone(user.leftHand, user.leftElbow);
            drawRGBBone(user.leftElbow, user.leftShoulder);
            drawRGBBone(user.leftShoulder, user.neck);

            drawRGBBone(user.rightHand, user.rightElbow);
            drawRGBBone(user.rightElbow, user.rightShoulder);
            drawRGBBone(user.rightShoulder, user.neck);

            drawRGBBone(user.head, user.neck);
            drawRGBBone(user.torso, user.neck);

            drawRGBBone(user.torso, user.leftHip);
            drawRGBBone(user.leftHip, user.leftKnee);
            drawRGBBone(user.leftKnee, user.leftFoot);

            drawRGBBone(user.torso, user.rightHip);
            drawRGBBone(user.rightHip, user.rightKnee);
            drawRGBBone(user.rightKnee, user.rightFoot);

            for each(var joint:SkeletonJoint in user.skeletonJoints) {
                rgbSkeletonContainer.graphics.lineStyle(2, 0xFFFFFF);
                rgbSkeletonContainer.graphics.beginFill(0xFF0000);
                rgbSkeletonContainer.graphics.drawCircle(joint.position.rgb.x, joint.position.rgb.y, 2);
                rgbSkeletonContainer.graphics.endFill();
            }
        }
    }

    private function drawRGBBone(from:SkeletonJoint, to:SkeletonJoint):void {
        rgbSkeletonContainer.graphics.lineStyle(3, 0xFF0000);
        rgbSkeletonContainer.graphics.moveTo(from.position.rgb.x, from.position.rgb.y);
        rgbSkeletonContainer.graphics.lineTo(to.position.rgb.x, to.position.rgb.y);
        rgbSkeletonContainer.graphics.lineStyle(0);
    }

    override protected function stopDemoImplementation():void {
        trace("[RiggedModelDemo] Stop Demo");
        removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
        if (device != null) {
            device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
            device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
            device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
            device.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
            device.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
            device.stop();
        }
        if (player != null) {
            player.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
            player.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
            player.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
            player.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
            player.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
            player.stop();
        }
        view.dispose();
    }

    override protected function layout():void {
        if (view != null) {
            view.width = explicitWidth;
            view.height = explicitHeight;
        }
    }
}
}