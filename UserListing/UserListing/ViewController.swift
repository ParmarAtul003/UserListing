
import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var arrUserListAllData:NSMutableArray = NSMutableArray();
    var arrUserList:NSMutableArray = NSMutableArray();
    var pageIndex:Int = 0;
    var PageLimit:Int = 10;
    var pagination:Bool = true;
    
    
    @IBOutlet var tblUserListing: UITableView!;
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tblUserListing.tableFooterView = UIView();
        
        if !getDataFromCoreData() {
            getUserDataFromAPI();
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK:- UITableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrUserList.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier : String = "UserCell";
        var cell : UserCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! UserCell;
        if (cell == nil) {
            cell = UserCell.init(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier);
        }
        
         cell.selectionStyle = .none;
        
        if (indexPath.row == self.arrUserList.count - 1) && (pagination) {
            pageIndex += PageLimit;
            _ = getDataFromCoreData();
        }
        
        let userInfo = arrUserList.object(at: indexPath.row) as! NSDictionary;
        

            cell.lblUser.text = userInfo.value(forKey: "name") as! String?;
            cell.imgUser.sd_setImage(with:  URL(string: userInfo.value(forKey: "userImage") as! String), placeholderImage: UIImage(named: "placeholderImage.png"));
            cell.imgUser.layer.cornerRadius = cell.imgUser.frame.size.height / 2;
       
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            let userInfo = arrUserList.object(at: indexPath.row) as! NSDictionary;
            
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest();
            fetchRequest.predicate = NSPredicate(format: "name = %@", userInfo.value(forKey: "name") as! String);
            let objects = try! context.fetch(fetchRequest);
            
            for object in objects {
                context.delete(object)
            }
            
            do {
                try context.save();
                
                arrUserList.removeObject(at: indexPath.row);
                arrUserListAllData.remove(userInfo);
                self.tblUserListing.reloadData();
            } catch {
                
            }
        }
    }
    
    //MARK:- Search bar Delegate Methods.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            arrUserList = arrUserListAllData;
            tblUserListing.reloadData();
        }else{
            searchDataFromArray(searchText);
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true);
        searchDataFromArray(searchBar.text!);
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true);
    }
    
    
    //MARK:- Search Result.
    func searchDataFromArray(_ strKeyword:String) {
        let resultPredicate = NSPredicate(format: "name contains[c] %@", strKeyword);
        arrUserList = NSMutableArray(array: arrUserListAllData.filtered(using: resultPredicate));
        tblUserListing.reloadData();
    }
    
    //MARK:- API Call.
    func getUserDataFromAPI() {
        let apiURL = NSURL(string: "https://api.github.com/users")
        let request:NSURLRequest = NSURLRequest(url: apiURL as! URL, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0);
        
        let session = URLSession.shared
        
        DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
        
        session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            if error == nil {
                do {
                    let response = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers);
                   
                    DispatchQueue.main.async { () -> Void in
                        
                        for userData in response as! NSArray {
                            self?.insertDataToLocalDB(userData as! NSDictionary);
                        }
                        
                        _ = self?.getDataFromCoreData();
                    };
                    
                } catch let myJSONError {
                    print(myJSONError);
                    let alert = UIAlertController(title: "Alert", message: "Something went wrong please try again later.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }else {
            
            }
            }.resume();
        };
        
    }
    
    //MARK:- Coredata Functions.
    func insertDataToLocalDB(_ userDic:NSDictionary) {
        
        let objRecentlyViewed = User(context: context)
        objRecentlyViewed.name = (userDic.value(forKey: "login") as! String);
        objRecentlyViewed.avatar_url = (userDic.value(forKey: "avatar_url") as! String);
        (UIApplication.shared.delegate as! AppDelegate).saveContext();
    }
    
    func getDataFromCoreData() -> Bool{
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User");
        fetchRequest.fetchLimit = PageLimit;
        fetchRequest.fetchOffset = pageIndex;
        do {
            
            let fetchData = try self.context.fetch(fetchRequest) as! [User] ;
            
            if fetchData.count == 0 {
                return false;
            }
            
            if fetchData.count < PageLimit {
                pagination = false;
            }
            
            for userData in fetchData {
                let userDic = NSMutableDictionary();
                userDic.setValue(userData.name, forKey: "name");
                userDic.setValue(userData.avatar_url, forKey: "userImage");
                self.arrUserListAllData.add(userDic);
            }
            
            self.arrUserList = self.arrUserListAllData;
            if self.arrUserList.count > 0 {
                self.tblUserListing.reloadData();
                return true;
            }
        } catch {
            print(error)
        }
        return false;
    }
    
}

