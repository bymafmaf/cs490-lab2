//
//  PhotosViewController.swift
//  Lab-TumblrAPI
//
//  Created by monus on 02/02/2017.
//  Copyright © 2017 Mufi. All rights reserved.
//

import UIKit
import AFNetworking

class PhotosViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var posts: [NSDictionary] = []
    var lastIndexOfPosts: Int?
    var loadingView: InfiniteScrollActivityView?
    let urlString = "https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV"
    
    @IBOutlet weak var mainTableView: UITableView!
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated:true)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCellTableViewCell
        
        let onePost = posts[indexPath.row]
        if let posts = onePost.value(forKeyPath: "photos") as? [NSDictionary] {
            // photos is NOT nil, go ahead and access element 0 and run the code in the curly braces
            let imageUrlString = posts[0].value(forKeyPath: "original_size.url") as? String
            let imageUrl = URL(string: imageUrlString!)
                // URL(string: imageUrlString!) is NOT nil, go ahead and unwrap it and assign it to imageUrl and run the code in the curly braces
            cell.postImageView?.setImageWith(imageUrl!)
            
        } else {
            // photos is nil. Good thing we didn't try to unwrap it!
        }
        
        let username = onePost.value(forKey: "blog_name") as! String
        let stringUrlForAvatar = "https://api.tumblr.com/v2/blog/" + username + "/avatar/512"
        cell.profileImageView.setImageWith(URL(string: stringUrlForAvatar)!)
        cell.usernameLabel.text = username
        

        
        return cell
    }
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options:[]) as? NSDictionary {
                        //print("responseDictionary: \(responseDictionary)")
                        
                        // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                        // This is how we get the 'response' field
                        let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                        
                        // This is where you will store the returned array of posts in your posts property
                        self.posts = responseFieldDictionary["posts"] as! [NSDictionary]
                        self.mainTableView.reloadData()
                        refreshControl.endRefreshing()
                    }
                }
        });
        task.resume()
    }
    
    var isLoading: Bool = false
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Handle scroll behavior here
        
        if (!isLoading){
            let scrollViewContentHeight = mainTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - mainTableView.bounds.size.height
            
            if(scrollView.contentOffset.y > scrollOffsetThreshold && mainTableView.isDragging) {
                isLoading = true
                loadMoreData()
                
            }
        }
        
    }
    
    func loadMoreData(){
        // Update position of loadingMoreView, and start loading indicator
        let frame = CGRect(x: 0, y: mainTableView.contentSize.height, width: mainTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingView?.frame = frame
        loadingView!.startAnimating()
        let offsetUrlString = urlString + "&offset=\(lastIndexOfPosts!)"
        let request = URLRequest(url: URL(string: offsetUrlString)!)
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            self.isLoading = false
            self.loadingView!.stopAnimating()
            if let data = data {
                if let responseDictionary = try! JSONSerialization.jsonObject(
                    with: data, options:[]) as? NSDictionary {
                    //print("responseDictionary: \(responseDictionary)")
                    
                    // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                    // This is how we get the 'response' field
                    let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                    print("appending")
                    self.posts.append(contentsOf: responseFieldDictionary["posts"] as! [NSDictionary])
                    self.lastIndexOfPosts = self.posts.count
                    self.mainTableView.reloadData()
                }
            }
            
                                                                        
            self.mainTableView.reloadData()
        });
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up Infinite Scroll loading indicator
        let frame = CGRect(x: 0, y: mainTableView.contentSize.height, width: mainTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingView = InfiniteScrollActivityView(frame: frame)
        loadingView!.isHidden = true
        mainTableView.addSubview(loadingView!)
        
        var insets = mainTableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        mainTableView.contentInset = insets
        
        mainTableView.delegate = self
        mainTableView.dataSource = self

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        self.mainTableView.insertSubview(refreshControl, at: 0)
        
        // Do any additional setup after loading the view.
        let url = URL(string:urlString)
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options:[]) as? NSDictionary {
                        //print("responseDictionary: \(responseDictionary)")
                        
                        // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                        // This is how we get the 'response' field
                        let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                        
                        // This is where you will store the returned array of posts in your posts property
                        self.posts = responseFieldDictionary["posts"] as! [NSDictionary]
                        self.lastIndexOfPosts = self.posts.count
                        self.mainTableView.reloadData()
                    }
                }
        });
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let destVC = segue.destination as! PhotoDetailsViewController
        let chosenPost = posts[(mainTableView.indexPath(for: sender as! UITableViewCell)?.row)!]
        
        if let urlString = (chosenPost.value(forKeyPath: "photos") as? [NSDictionary])?[0].value(forKeyPath: "original_size.url") as? String {
           destVC.imageUrl = urlString
        }
        
    }
 

}
