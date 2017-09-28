
import UIKit

class UserCell: UITableViewCell {

    @IBOutlet var imgUser: UIImageView!;    
    @IBOutlet var lblUser: UILabel!;
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
