//
//  AnimationType.swift
//  MacPet
//
//  Created by MacPet on 2026/8/23.
//
//  动画类型定义，直接对应 dsh-pet/assets/thumb 中的中文 webm 文件
//

import Foundation

/// 动画场景分类
enum AnimationCategory: String, CaseIterable {
    case idle = "待机"
    case turn = "转向"
    case move = "移动"
    case action = "动作"
    case interact = "交互"
    case work = "工作"
    case eat = "进食"
    case emotion = "情绪"
    case play = "玩耍"
    case festival = "节日"
    case drag = "拖拽"
    case stretch = "伸展"
    case special = "特殊"
}

/// 动画类型定义，对应 dsh-pet 实际中文文件名
enum AnimationType: String, CaseIterable, Identifiable {
    // MARK: - 待机类
    case daijihuxi = "待机呼吸休闲"
    case xiuxian = "是啊，吃什么"
    case dongzhangxiwang = "东张西望"
    case dakaishui = "打瞌睡被惊醒"
    case shuijiao = "原地小憩沉眠"
    case haqian = "哈欠连天"
    case nupuqianli = "女仆屈膝礼仪"
    case xuanzhuan = "小幅度原地360度旋转展示"
    
    // MARK: - 移动类
    case zouhu = "螃蟹走路"
    case yuanpao = "原地左转奔跑"
    case piaofutabu = "原地漂浮踏步"
    case paiji = "用鲸鱼尾巴拍打地面"
    case xiadun = "原地重力下蹲压缩"
    case yaobai = "鲸鱼吐泡泡特效"
    
    // MARK: - 点击/交互类
    case dianjikaixin = "点击回应-开心跃动"
    case dianjishaonu = "点击回应-害羞惊讶"
    case dianjiaojiao = "点击回应-傲娇生气"
    case dianjiyuanqi = "点击回应-元气挥手"
    case dianjinaoyang = "点击回应-挠痒咯咯笑"
    case beixiayitiao = "被吓一跳"
    case qiaoji = "原地敲击桌面互动"
    
    // MARK: - 伸展/动作
    case shenlanya = "超大伸懒腰"
    
    // MARK: - 进食类
    case chibaihuafan = "吃白饭"
    case dakouchilingshi = "大口吃零食"
    case chizaocan = "吃早餐"
    case chiwucan = "吃午餐"
    case chiwancan = "吃晚餐"
    case chitangyuan = "吃汤圆"
    case chijiaozi = "吃饺子"
    case chibingqilin = "吃冰淇淋融化"
    case chidazhaxie = "吃大闸蟹"
    case chiniangao = "吃年糕"
    case chizongzi = "吃粽子"
    case chitanghulu = "吃糖葫芦"
    case chixigua = "吃西瓜"
    case chichongyanggao = "吃重阳糕"
    case chichangshoumian = "吃长寿面"
    case chiqingtuan = "吃青团"
    case chilabazhou = "吃腊八粥"
    case chitoken = "吃Token"
    case chihuoguo = "涮火锅"
    case toushichilingshi = "偷吃零食被抓住"
    
    // MARK: - 等待/情绪
    case dengdai = "摇扇纳凉"      // 休闲等待
    case shengqi = "玩游戏气急败坏" // 生气
    case shuxiya = "晨间刷牙"
    
    // MARK: - 工作类
    case xiedaima = "写代码"
    case kuaijijilu = "轻快记录"
    case shendusikao = "深度思考碎碎念"
    case wanmofang = "原地专心玩魔方"
    case wuziqi = "下五子棋"
    case xieyou = "写福字"
    
    // MARK: - 玩耍/动作类
    case hengge = "悠闲哼歌"
    case tupaopao = "蓝鲸现世"  // 鲸鱼吐泡泡
    case wanshuiqiang = "玩水枪"
    case laxiaotiqin = "小提琴演奏"
    case daoqiuhang = "荡秋千"
    case nupuwu = "优雅女仆舞"
    case yaobaiwu = "轻快摇摆舞"
    case zhaiwu = "可爱宅舞"
    case huanzhuang = "整体换装试色"
    case chuiqiqu = "吹气球"
    case chuidizi = "吹笛子"
    case dongwuhuanrao = "动物环绕"
    case hudiekaihua = "蝴蝶蜜蜂环绕头顶开花"
    case zhaojingzi = "照镜子"
    case wanqiche = "原地蹲下玩玩具汽车"
    case zhuawupin = "原地跳跃抓碎头顶物品"
    case sanqiupaojei = "三球抛接"
    case biankezi = "变鸽子"
    case pukemoshu = "扑克魔术"
    case pingkongshenghua = "凭空生花"
    case lumao = "撸猫"
    case qimuma = "骑木马"
    case tuoluo = "抽陀螺"
    case tujianzi = "踢毽子"
    case menghuayouling = "萌化小幽灵"
    
    // MARK: - 节日/特殊
    case chiyuebing = "中秋赏月吃月饼"
    case fangkongmingdeng = "放孔明灯"
    case fanghedeng = "放河灯"
    case luoyemanmou = "被落叶淹没"
    case chuanzhenqiao = "穿针乞巧"
    case chazhuyushangju = "插茱萸赏菊"
    case duixueren = "堆雪人"
    case shoulahongbao = "收红包"
    case fangyanhua = "放烟花"
    case fangfengzheng = "放风筝"
    case chailiwu = "拆礼物"
    case zhuangdianshengdanshu = "装点圣诞树"
    case tangnangguadeng = "讨糖南瓜灯"
    case wushitou = "舞狮头"
    
    // MARK: - 拖拽
    case tuozhuai = "被鼠标拖拽悬空反馈"
    
    // MARK: - 爱心/情绪映射
    case aixin = "蝴蝶蜜蜂环绕头顶开花"  // 爱心用环绕开花代替
    case kaiixin = "点击回应-开心跃动"
    
    var id: String { rawValue }
    
    /// 显示名称
    var displayName: String { rawValue }
    
    /// 所属分类
    var category: AnimationCategory {
        switch self {
        case .daijihuxi, .xiuxian, .dongzhangxiwang, .dakaishui, .shuijiao,
             .haqian, .nupuqianli, .xuanzhuan:
            return .idle
        case .zouhu, .yuanpao, .piaofutabu, .paiji, .xiadun, .yaobai:
            return .move
        case .wanmofang, .hengge, .tupaopao, .wanshuiqiang, .laxiaotiqin,
             .daoqiuhang, .nupuwu, .yaobaiwu, .zhaiwu, .huanzhuang,
             .chuiqiqu, .chuidizi, .dongwuhuanrao, .hudiekaihua,
             .zhaojingzi, .wanqiche, .zhuawupin, .sanqiupaojei,
             .biankezi, .pukemoshu, .pingkongshenghua, .lumao, .qimuma,
             .tuoluo, .tujianzi, .menghuayouling, .qiaoji:
            return .play
        case .dianjikaixin, .dianjishaonu, .dianjiaojiao, .dianjiyuanqi,
             .dianjinaoyang, .beixiayitiao:
            return .interact
        case .shenlanya:
            return .stretch
        case .chibaihuafan, .dakouchilingshi, .chizaocan, .chiwucan,
             .chiwancan, .chitangyuan, .chijiaozi, .chibingqilin,
             .chidazhaxie, .chiniangao, .chizongzi, .chitanghulu,
             .chixigua, .chichongyanggao, .chichangshoumian, .chiqingtuan,
             .chilabazhou, .chitoken, .chihuoguo, .toushichilingshi, .shuxiya:
            return .eat
        case .dengdai:
            return .action
        case .shengqi:
            return .emotion
        case .xiedaima, .kuaijijilu, .shendusikao, .wuziqi, .xieyou:
            return .work
        case .aixin, .kaiixin:
            return .emotion
        case .tuozhuai:
            return .drag
        case .chiyuebing, .fangkongmingdeng, .fanghedeng, .luoyemanmou,
             .chuanzhenqiao, .chazhuyushangju, .duixueren, .shoulahongbao,
             .fangyanhua, .fangfengzheng, .chailiwu, .zhuangdianshengdanshu,
             .tangnangguadeng, .wushitou:
            return .festival
        }
    }
    
    /// 是否循环播放（一次性动作播完回到待机）
    var shouldLoop: Bool {
        switch self {
        case .shenlanya, .beixiayitiao, .dianjikaixin, .dianjishaonu,
             .dianjiaojiao, .dianjiyuanqi, .dianjinaoyang,
             .shengqi, .kaiixin, .aixin, .chailiwu, .menghuayouling:
            return false
        default:
            return true
        }
    }
    
    /// 动画默认权重（用于随机选择，值越大概率越高）
    var weight: Int {
        switch self {
        case .daijihuxi: return 40
        case .dongzhangxiwang: return 20
        case .hengge: return 15
        case .piaofutabu: return 15
        case .tupaopao: return 12
        case .dakaishui, .haqian: return 8
        case .nupuwu, .yaobaiwu, .zhaiwu: return 6
        default: return 5
        }
    }
    
    /// 专注模式下的权重（大幅提升工作类，降低玩耍类）
    var focusWeight: Int {
        switch category {
        case .work: return 45
        case .idle: return 30
        case .eat: return 4
        case .play, .festival: return 2
        default: return 3
        }
    }
}
