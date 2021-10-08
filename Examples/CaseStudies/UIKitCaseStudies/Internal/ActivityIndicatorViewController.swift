import UIKit

final class ActivityIndicatorViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    let activityIndicator = UIActivityIndicatorView()
    activityIndicator.startAnimating()
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(activityIndicator)
    
    NSLayoutConstraint.activate([
      activityIndicator.centerXAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
  }
}
