//
//  LJMMultiLevelTableView.swift
//  test
//
//

import UIKit

/***************************  工具  ***********************************************/
/// 窗口宽度
var QDEV_W = UIScreen.main.bounds.size.width
/// 获取视图当前宽度
func GETVW(_ view : UIView) ->CGFloat { return view.frame.width }
/// 获取视图高度
func GETVH(_ view : UIView) ->CGFloat { return view.frame.height }

func QRect(_ X : CGFloat , Y : CGFloat , W : CGFloat , H : CGFloat) ->CGRect { return CGRect(x: X, y: Y, width: W, height: H) }

typealias leafObj = ()->Void
typealias ResObj = (_ obj: Any)->Void

/// 点击手势
class QTapGesture: UITapGestureRecognizer {
    
    var tapend : ResObj?
    
    class func addguest(_ view : UIView , action : @escaping ResObj){
        let tap = QTapGesture.init();
        tap.tapend = action
        tap.addTarget(tap, action: #selector(QTapGesture.tapgesture(_:)));
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
    }
    
    func tapgesture(_ tap : UITapGestureRecognizer){
        if (self.tapend != nil){
            self.tapend!(tap.view!)
        }
    }
}

//四个角变圆(未使用)
func setAllround(_ view : UIView,size : CGFloat,corners:UIRectCorner){
    let path = UIBezierPath.init(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: size, height: size))
    let layer = CAShapeLayer()
    layer.frame = view.bounds
    layer.path = path.cgPath
    
    
    view.layer.mask = layer
    layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
}

///色值一样的
func RGBAsame(_ RGB : Double , A : CGFloat) ->UIColor { return UIColor.init(red: CGFloat(RGB/255.0), green: CGFloat(RGB/255.0), blue: CGFloat(RGB/255.0), alpha: A) }

/*************************************************************************************/


class LJMMultiLevelTableView: UITableView ,UITableViewDelegate,UITableViewDataSource{
    
    var companys : [CTMLObj] = []
    
    var tempNodes : [[MLNodelObj]] = []     //当前展示的节点数据,每个元素数组存储的是每个组里面的所有正在展示的cell
    var reloadArray : [IndexPath]!          //存储要插入的数据
    
    var leafblock : leafObj!                //点击叶子回调
    
    var preservation : Bool = false         //收起后再展开是否保留之前的展开状态
    
    private var isInitializeed : Bool = false   //是否已经初始化过
    
    convenience init(_ frame : CGRect ,needPreservation : Bool, objs : AnyObject?){
        self.init(frame: frame, style: UITableViewStyle.grouped)
        if objs != nil {
            companys = objs as! [CTMLObj]
        }
        for _ in 0..<companys.count {
            tempNodes.append([MLNodelObj]())
        }
        preservation = needPreservation
        isInitializeed = true
    }
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        self.backgroundColor = UIColor.white
        reloadArray = [IndexPath]()
        self.delegate = self
        self.dataSource = self
        self.separatorStyle = UITableViewCellSeparatorStyle.none
        self.register(CTMLCell.self, forCellReuseIdentifier: "CTMLCell")
        self.register(CTMLCHeaderView.self, forHeaderFooterViewReuseIdentifier: "CTMLCHeader")
        isInitializeed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //刷新列表
    func reloadNode(_ nodes: AnyObject){
        if !isInitializeed { return }
        self.companys = nodes as! [CTMLObj]
        tempNodes.removeAll()
        reloadArray.removeAll()
        for _ in 0..<companys.count {
            tempNodes.append([MLNodelObj]())
        }
        self.reloadData()
    }
    
    
    //多少个组
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.companys.count
    }
    //每组多少cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tempNodes[section].count
    }
    //自定义组头
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CTMLCHeader") as! CTMLCHeaderView
        let comobj = companys[section]
        head.setInfo(comobj)
        head.tap = { (obj) in
            
            comobj.isopen = !comobj.isopen
            
            if comobj.isopen {
                let _ = self.expandNodes(section: section, parentID: comobj.ownID, index: -1)
            }else{
                self.tempNodes[section].removeAll()
            }
            self.reloadArray.removeAll()
            tableView.reloadSections(IndexSet(integer: section), with: UITableViewRowAnimation.automatic)
            
        }
        return head
    }
    //组头高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    //组尾高度
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    //每个cell高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    //设置cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CTMLCell", for: indexPath) as! CTMLCell
        let obj = tempNodes[indexPath.section][indexPath.row]
        cell.setcellinfo(obj)
        
        return cell
    }
    //点击cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentnode = tempNodes[indexPath.section][indexPath.row]
        if currentnode.leaf {
            print("点击叶子,\(currentnode.name)")
            if self.leafblock != nil {
                self.leafblock()
            }
            return
        }else{
            currentnode.expand = !currentnode.expand
        }
        reloadArray.removeAll()
        
        if currentnode.expand {
            let _ = self.expandNodes(section: indexPath.section, parentID: currentnode.ownID, index: indexPath.row)
            //插入cell
            tableView.insertRows(at: reloadArray as [IndexPath], with: UITableViewRowAnimation.none)
        }else{
            self.foldNodes(section: indexPath.section, level: currentnode.level, currentIndex: indexPath.row)
            //删除cell
            tableView.deleteRows(at: reloadArray, with: UITableViewRowAnimation.none)
        }
        //刷新这行cell的显示
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }
    
    //记录展开的数据
    func expandNodes(section : Int, parentID:String,index:Int)->Int{
        
        var insertindex = index
        
        for i in 0..<companys[section].subNodes.count {
            let node = companys[section].subNodes[i]
            //找到父节点是parentID的子节点
            if node.parentID == parentID {
                if !self.preservation {  //是否保留所有子cell的展开状态
                    node.expand = false
                }
                //展开节点的后面+1的位置
                insertindex += 1
                //根据展开顺序排列
                tempNodes[section].insert(node, at: insertindex)
                //存储插入的位置
                reloadArray.append(IndexPath(row: insertindex, section: section))
                //遍历子节点的子节点进行展开
                if node.expand {
                    insertindex = expandNodes(section : section, parentID: node.ownID, index: insertindex)
                }
            }
        }
        return insertindex
    }
    
    //记录收起的数据
    func foldNodes(section : Int,level:Int,currentIndex:Int){
        if currentIndex+1<tempNodes[section].count {
            
            let tempArr = NSArray(array: tempNodes[section])
            
            let startI = currentIndex+1
            var endI   = currentIndex
            for i in (currentIndex+1)..<(tempArr.count) {
                let node = tempArr[i] as! MLNodelObj
                if node.level <= level {
                    break
                }else{
                    endI += 1
                    reloadArray.append(IndexPath(row: i, section: section))
                }
            }
            if endI >= startI {
                tempNodes[section].removeSubrange(startI...endI)
            }
        }
    }
}

/****************   组头    ***************************/
class CTMLCHeaderView: UITableViewHeaderFooterView {
    
    var bgv       : UIView!
    var descLbl   : UILabel!
    var imgBtn    : UIButton!
    
    var tap : ResObj!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        creatView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func creatView(){
        bgv = UIView(frame: QRect(15, Y: 0, W: QDEV_W - 30, H: 50))
        bgv.backgroundColor = RGBAsame(233, A: 1.0)
        bgv.layer.borderColor = RGBAsame(211, A: 1.0).cgColor
        bgv.layer.borderWidth = 1.0
        bgv.layer.cornerRadius = 5
        bgv.layer.masksToBounds = true
        
        let imgw : CGFloat = 30
        imgBtn = UIButton(frame: QRect(GETVW(bgv)-imgw, Y: (GETVH(bgv)-imgw)/2.0, W: imgw, H: imgw))
        imgBtn.isUserInteractionEnabled = false
        imgBtn.setImage(UIImage(named: "jiahao"), for: UIControlState.normal)
        imgBtn.setImage(UIImage(named: "jianhao"), for: UIControlState.selected)
        imgBtn.imageView?.contentMode = .scaleAspectFit
        imgBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        bgv.addSubview(imgBtn)
        
        descLbl = UILabel(frame: QRect(10, Y: 0, W: GETVW(bgv)-10-imgw, H: GETVH(bgv)))
        descLbl.font = UIFont.systemFont(ofSize: 13)
        descLbl.textColor = UIColor.black
        descLbl.textAlignment = NSTextAlignment.left
        descLbl.backgroundColor = bgv.backgroundColor
        bgv.addSubview(descLbl)
        
        self.addSubview(bgv)
        
        QTapGesture.addguest(bgv) { (obj) in
            if self.tap != nil { self.tap(obj) }
        }
    }
    
    func setInfo(_ obj : CTMLObj){
        descLbl.text = obj.name
        imgBtn.isSelected = obj.isopen
    }
    
}

class CTMLCell: UITableViewCell {
    
    var bgv       : UIView!
    var descLbl   : UILabel!
    var imgBtn    : UIButton!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.frame = QRect(0, Y: 0, W: QDEV_W, H: 0)
        
        creatsubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func creatsubview() {
        self.selectionStyle = UITableViewCellSelectionStyle.none
        
        bgv = UIView(frame: QRect(15, Y: 0, W: QDEV_W - 30, H: 50))
        bgv.backgroundColor = RGBAsame(245, A: 1.0)
        bgv.layer.borderColor = RGBAsame(211, A: 1.0).cgColor
        bgv.layer.borderWidth = 1.0
        
        let imgw : CGFloat = 30
        imgBtn = UIButton(frame: QRect(GETVW(bgv)-imgw, Y: (GETVH(bgv)-imgw)/2.0, W: imgw, H: imgw))
        imgBtn.isUserInteractionEnabled = false
        imgBtn.setImage(UIImage(named: "unopen"), for: UIControlState.normal)
        imgBtn.setImage(UIImage(named: "open"), for: UIControlState.selected)
        imgBtn.imageView?.contentMode = .scaleAspectFit
        imgBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        bgv.addSubview(imgBtn)
        
        descLbl = UILabel(frame: QRect(10, Y: 0, W: GETVW(bgv)-10-imgw, H: GETVH(bgv)))
        descLbl.font = UIFont.systemFont(ofSize: 13)
        descLbl.textColor = UIColor.black
        descLbl.textAlignment = NSTextAlignment.left
        descLbl.backgroundColor = bgv.backgroundColor
        bgv.addSubview(descLbl)
        
        self.addSubview(bgv)
    }
    
    func setcellinfo(_ id: AnyObject) {
        let obj = id as! MLNodelObj
        descLbl.text = obj.name
        imgBtn.isSelected = obj.expand
        imgBtn.isHidden = obj.leaf
        layoutView(obj)
    }
    
    func layoutView(_ obj : MLNodelObj){
        let interval : CGFloat = 30
        var leMargin : CGFloat = 10
        for _ in 2...obj.level {
            leMargin += interval
        }
        
        descLbl.frame = QRect(leMargin, Y: 0, W: GETVW(bgv)-leMargin-30, H: GETVH(bgv))
        bgv.backgroundColor = obj.level == 2 ? RGBAsame(245, A: 1.0) : RGBAsame(255, A: 1.0)
        descLbl.backgroundColor = bgv.backgroundColor
    }
    
    
    
}



class CTMLObj : NSObject{
    
    var name      : String = ""
    var ownID     : String = ""     //自身ID
    var level     : Int    =  1
    var isopen    : Bool   = false
    
    var subNodes  : [MLNodelObj] = []
    
    class func node(ownID:String,name:String,level:NSInteger)->CTMLObj{
        let ctmlobj = CTMLObj()
        ctmlobj.name = name
        ctmlobj.ownID = ownID
        ctmlobj.level = level
        return ctmlobj
    }
    
}


//节点数据
class MLNodelObj: NSObject {
    
    var parentID  : String = ""     //父ID
    var ownID     : String = ""     //自身ID
    var name      : String = ""     //自身内容
    var level     : NSInteger = 0   //级别
    var expand    : Bool = false    //是否展开
    var leaf      : Bool = false    //是否叶子(没有子节点)
    var root      : Bool = false    //是否根节点
    
    class func node(parentID:String,ownID:String,name:String,level:NSInteger,isleaf:Bool,isroot:Bool,isExpand:Bool)->MLNodelObj{
        let mlnode = MLNodelObj()
        mlnode.parentID = parentID
        mlnode.ownID = ownID
        mlnode.name = name
        mlnode.level = level
        mlnode.leaf = isleaf
        mlnode.root = isroot
        mlnode.expand = isExpand
        
        return mlnode
    }
    
}










