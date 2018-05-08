//
//  MonkeyFilter.swift
//  Monkey
//
//  Created by 王广威 on 2018/3/20.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit
import ObjectMapper

public enum FaceShape: Int {
	case Default = 3
	case Goddes = 0
	case NetReds = 1
	case Natural = 2
}

class MonkeyFilter: Mappable {
	/**
	*  显示的标题
	*/
	var filter_title: String?
	/**
	*  去掉空格，大写转小写，作为 bundle 名字
	*/
	var filter_real_title: String?
	/**
	*  滤镜的图片icon url
	*/
	var filter_icon: String?
	/**
	*  滤镜资源包 url
	*/
	var resource_url: String?
	
	/**
	*  风格滤镜名称
	*/
	var filter_name: String?
	/**
	*  风格滤镜名称，如果是 faceunity 滤镜，大写转小写
	*/
	var filter_real_name: String?
	
	/**
	*  磨皮效果 0 - 6
	*/
	lazy var smooth_level: CGFloat = 0
	/**
	*  美白效果、风格滤镜效果 0 - 1
	*/
	lazy var filter_level: CGFloat = 0
	/**
	*  大眼效果 0 - 1
	*/
	lazy var eye_enlarging: CGFloat = 0
	/**
	*  瘦脸效果 0 - 1
	*/
	lazy var cheek_thinning: CGFloat = 0
	/**
	*  脸型 3 默认，0 女神，1 网红，2 自然
	*/
	lazy var face_shape: FaceShape = .Default
	/**
	*  程度 0 - 1
	*/
	lazy var face_shape_level: CGFloat = 0
	/**
	*  红润效果 0 - 1
	*/
	lazy var red_level: CGFloat = 0
	
	/**
	*  文件路径
	*/
	var resource_path: String?
	/**
	*  是否下载完成
	*/
	lazy var download_complete: Bool = false
	/**
	*  是否是 GPUImageFilter
	*/
	lazy var faceunity_filter: Bool = false
	/**
	*  是否是内置的贴图包
	*/
	lazy var built_in: Bool = false
	/**
	*  是否被选中
	*/
	lazy var spoted: Bool = false
	
	/**
	*  下载任务
	*/
	var download_task: URLSessionDownloadTask?
	/**
	*  下载进度
	*/
	var download_callback: ((_ progress: Float) -> Void)?
	
	required init?(map: Map) {
		
	}
	
	func mapping(map: Map) {
		filter_title <- map["filter_title"]
		filter_real_title <- map["filter_real_title"]
		filter_icon <- map["filter_icon"]
		resource_url <- map["resource_url"]
		
		filter_name <- map["filter_name"]
		filter_real_name <- map["filter_real_name"]
		smooth_level <- map["smooth_level"]
		filter_level <- map["filter_level"]
		eye_enlarging <- map["eye_enlarging"]
		cheek_thinning <- map["cheek_thinning"]
		face_shape <- map["face_shape"]
		face_shape_level <- map["face_shape_level"]
		red_level <- map["red_level"]
		
		resource_path <- map["resource_path"]
		download_complete <- map["download_complete"]
		faceunity_filter <- map["faceunity_filter"]
		built_in <- map["built_in"]
		spoted <- map["spoted"]
	}
}
