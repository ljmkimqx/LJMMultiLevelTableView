//
//  ViewController.swift
//  LJMMultiLevelTableView
//
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    var listobj : AnyObject!
    var levelList : LJMMultiLevelTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.path(forResource: "territory", ofType: "txt")
        
        let url = URL(fileURLWithPath: path!)
        
        do {
            let data = try Data(contentsOf: url)
            let jsondata = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            listobj = getdata(jsondata as AnyObject)

        } catch  {
            print("报错")
        }
        
        levelList = LJMMultiLevelTableView(QRect(0, Y: 50, W: GETVW(self.view), H: GETVH(self.view)-50), needPreservation: true, objs: listobj)
        self.view.addSubview(levelList)
        
        
    }
    
    func getdata(_ obj :AnyObject)->AnyObject{
        
        let dict = obj as! NSDictionary
        let array = dict["data"] as! NSArray
        var objs = [AnyObject]()
        
        //洲
        for obj in array{
            let continent = obj as! NSDictionary
            let continentName = continent["洲"] as! String
            let continentid   = continent["continentID"] as! String
            let continentC = CTMLObj.node(ownID: continentid, name: continentName, level: 1)
            objs.append(continentC)
            
            //国家
            let countryArray = continent["国家"] as? NSArray
            if countryArray != nil{
                for obj in countryArray!{
                    let country = obj as! NSDictionary
                    let countryName = country["国家名称"] as! String
                    let countryid = country["countryID"]  as! String
                    let countryM = MLNodelObj.node(parentID: continentid, ownID: countryid, name: countryName, level: 2, isleaf: false, isroot: false, isExpand: false)
                    continentC.subNodes.append(countryM)
                    
                    //城市
                    let cityArray = country["城市"] as? NSArray
                    if cityArray != nil{
                        for obj in cityArray!{
                            let city = obj as! NSDictionary
                            let cityName = city["城市"] as! String
                            let cityid   = city["cityID"] as! String
                            let cityM = MLNodelObj.node(parentID: countryid, ownID: cityid, name: cityName, level: 3, isleaf: true, isroot: false, isExpand: false)
                            continentC.subNodes.append(cityM)
                        }
                    }
                }
            }
        }
        
        return objs as AnyObject
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

