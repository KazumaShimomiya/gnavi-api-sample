//
//  ViewController.swift
//  gnavi-api-sample
//
//  Created by Shimomiya Kazuma on 2017/03/28.
//  Copyright © 2017年 kshimomiya. All rights reserved.
//

import UIKit
import MapKit
import SafariServices

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {

  @IBOutlet weak var searchText: UISearchBar!
  @IBOutlet weak var responseTableView: UITableView!
  
  var restaurantList : [(name: String, url: String, image: String)] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    searchText.delegate = self
    searchText.placeholder = "場所を入力してください。"

    responseTableView.dataSource = self
    responseTableView.delegate = self
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // searchButtonClicked Action
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    view.endEditing(true)

    if let searchWord = searchBar.text {
      let geocoder = CLGeocoder()
      geocoder.geocodeAddressString(searchWord, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) in
        if let placemark = placemarks?[0] {
          if let targetCoordinate = placemark.location?.coordinate {
            self.searchRestaurant(latitude: String(targetCoordinate.latitude), longtude: String(targetCoordinate.longitude))
          }
        } else {
          print("該当する位置情報なし。")
        }
      })
    }
  }

  func searchRestaurant(latitude: String, longtude: String) {
    let latitude_encode = latitude.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    let longtude_encode = longtude.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)

    // keyidはサンプルのため、日毎に変更される。
    let url = "https://api.gnavi.co.jp/RestSearchAPI/20150630/?keyid=f08264bfb0a673f6b2fa1c77e1af3ee2&format=json&latitude=\(latitude_encode!)&longitude=\(longtude_encode!)"

    let requestURL = Foundation.URL(string: url)
    // print(requestURL!)
    
    // request用のオブジェクト生成
    let req = URLRequest(url: requestURL!)
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
    let task = session.dataTask(with: req, completionHandler: {
      (data, request, error) in
      do {
        let json = try JSONSerialization.jsonObject(with: data!) as! [String: Any]
        self.restaurantList.removeAll()
        if let items = json["rest"] as? [[String: Any]] {
          // print (items)
          for item in items {
            guard let name = item["name"] as? String else {
              continue
            }
            guard let url = item["url_mobile"] as? String else {
              continue
            }
            if let images = item["image_url"] as? [String: Any] {
              guard let image_url = images["shop_image1"] as? String else {
                // print("image_urlなし")
                let rest = (name, url, "")
                self.restaurantList.append(rest)
                continue
              }
              let rest = (name, url, image_url)
              self.restaurantList.append(rest)
            } else {
              // print("image_urlなし")
              let rest = (name, url, "")
              self.restaurantList.append(rest)
              continue
            }
          }
        }
        self.responseTableView.reloadData()
      } catch {
        print ("エラーがでました。")
      }
    })
    task.resume()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return restaurantList.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "researchCell", for: indexPath)
    cell.textLabel?.text = restaurantList[indexPath.row].name
    if let url = URL(string: restaurantList[indexPath.row].image) {
      if let image_data = try? Data(contentsOf: url) {
        cell.imageView?.image = UIImage(data: image_data)
      }
    } else {
      cell.imageView?.image = UIImage(named: "noimage.png")
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let urlToLink = URL(string: restaurantList[indexPath.row].url)
    let safariViewController = SFSafariViewController(url: urlToLink!)
    safariViewController.delegate = self
    present(safariViewController, animated: true, completion: nil)
  }
  
  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    dismiss(animated: true, completion: nil)
  }
}
