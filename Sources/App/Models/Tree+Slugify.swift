//
//  Tree+Slugify.swift
//  App
//
//  Created by Hadi Sharghi on 12/11/19.
//


extension TreeNode where T: AstinCategory {
    
    func toCode() -> String {
        var codes = [String]()
        
        var c: TreeNode<AstinCategory>? = self as? TreeNode<AstinCategory>
        
        while c != nil {
            codes.append(c!.value.title.slugify())
            c = c!.parent
        }
        
        let code = codes.reversed().joined(separator: "-")
        return code
    }
    
    func toSlug() -> String {
            
            var codes = [String]()
            
            var c: TreeNode<AstinCategory>? = self as? TreeNode<AstinCategory>
            
            while c != nil {
                codes.append(c!.value.title)
                c = c!.parent
            }
            
            let code = codes.reversed().joined(separator: "/")
            return code

    }
    
    
}

