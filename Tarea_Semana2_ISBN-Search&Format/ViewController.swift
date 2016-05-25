//
//  ViewController.swift
//  Tarea_Semana2_ISBN-Search&Format
//
//  Created by Diseño01 on 23/05/16.
//  Copyright © 2016 DanTuknal. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var isbnTextField: UITextField!
    @IBOutlet weak var botLimpiar: UIButton!
    @IBOutlet weak var titulo: UILabel!
    @IBOutlet weak var autores: UILabel!
    @IBOutlet weak var cover: UIImageView!
    @IBOutlet weak var by_statement: UILabel!
    
    let isbnVacio = "Ingresa el ISBN que deseas buscar"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        isbnTextField.delegate=self
        
        //Aunque se indique que le clear button este visible siempre no aparecerá si el campo de texto esta vacío ya que no hay nada que borrar.
        isbnTextField.clearButtonMode = UITextFieldViewMode.Always
        isbnTextField.text = isbnVacio
        
        initializeTextFields()
        
        reset()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func textFieldDoneEditing(sender:UITextField){
        //Desaparece el teclado al presionar INTRO/SEARCH/etc
        sender.resignFirstResponder()
        sincrono ()
    }
    
    @IBAction func backgroundTap(sender:UIControl){
        //Desaparece el teclado cuando toco fuera del campo
        isbnTextField.resignFirstResponder()
    }
    
    @IBAction func buscarISBN(sender: AnyObject) {
        sincrono ()
    }
    
    @IBAction func limpiarCampos(sender: AnyObject) {
        isbnTextField.text = isbnVacio
        
        reset()
    }
    
    func sincrono (){
        //el isbn a capturar
        var isbnBuscar = isbnTextField.text!
        if isbnBuscar == isbnVacio {
            isbnBuscar = ""
        }
        
        reset()
        
        //creo la url
        let urls = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:"
        let url = NSURL(string: urls+isbnBuscar)
        let datos : NSData? =  NSData (contentsOfURL: url!)
        
        //valido conexion a internet y si la peticion vuelve vacía porque no encontró el isbn que buscamos -> {}
        if datos == nil{
            
            errorAlert("Error en la conexion", mensaje: "Hay un problema con tu conexión a internet. Por favor, checala e intenta de nuevo.")
            
        }else {
            
            let texto = NSString(data:datos!, encoding:NSUTF8StringEncoding)
            
            
            if texto != "{}"{
                
                do {
                    
                    //print(texto)
                    
                    let json = try NSJSONSerialization.JSONObjectWithData(datos!, options: NSJSONReadingOptions.MutableLeaves)
                    
                    let dato1 = json as! NSDictionary
                    let dato2 = dato1["ISBN:\(isbnBuscar)"] as! NSDictionary
                    
                    if (dato2["title"] != nil) {
                        titulo.text = "\"\(dato2["title"] as! String)\""
                        titulo.sizeToFit()
                        titulo.textColor = UIColor.blackColor()
                    }
                   
                    if (dato2["authors"] != nil){
                        //print(dato2["authors"]!.count)
                        autores.text = ""
                        autores.textColor = UIColor.blackColor()
                        var addField = ""
                        var addAuthor = ""
                        let dato3 = dato2["authors"] as! NSArray
                        
                        for var i = 0; i < dato2["authors"]!.count; i++ {
                            //print(dato3[i]["name"] as! String)
                            
                            addAuthor = dato3[i]["name"] as! String
                            addField = self.autores.text!
                            if i == 0 {
                                autores.text = "Autores:\n\(addAuthor)"
                            } else {
                                autores.text = "\(addField), \(addAuthor)"
                            }
                        }
                        autores.sizeToFit()
                    }
                    
                    if (dato2["by_statement"] != nil){
                    let addStatementAuthors = (dato2["by_statement"] as! String)
                    by_statement.text = addStatementAuthors
                    by_statement.sizeToFit()
                    by_statement.hidden = false
                    }
                    
                    if (dato2["cover"] != nil){
                        let dato4 = dato2["cover"]
                        if (dato4!["medium"] != nil){
                            downloadImage ((dato4!["medium"] as! String))
                            //print((dato4!["medium"] as! String))
                        }
                    } else {
                        cover.image = UIImage(named: "image1")
                    }
                    
                    titulo.hidden = false
                    autores.hidden = false
                    cover.hidden = false
                    
                    /*
                    */
                }
                
                catch _ {
                    
                }
                
            }else{
                
                self.errorAlert("Error en el ISBN", mensaje: "No se encontró un libro asociado al ISBN:\(isbnBuscar) que ingresaste. Por favor, intenta de nuevo con otro ISBN.\n\nMuchas gracias!")
                
            }
            
        }
        
    }
    
    func errorAlert (error: String, mensaje: String) {
        let alert: UIAlertController = UIAlertController(title: error, message: mensaje, preferredStyle: UIAlertControllerStyle.Alert)
        let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func downloadImage (urlString:String){
        let request = NSURLRequest(URL: NSURL(string: urlString)!)
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            if error != nil {
                print("No se pudo descargar la imagen: \(urlString), error: \(error?.description)")
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                print("No es un NSHTTPURLResponse al cargar la url: \(urlString)")
                return
            }
            
            if httpResponse.statusCode != 200 {
                print("Mala respuesta statusCode: \(httpResponse.statusCode) al cargar la url: \(urlString)")
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.cover.image = UIImage(data: data!)
            })
            
            }.resume()
    }
    
    func reset(){
        titulo.text = "{ No se encontró titulo para este libro }"
        autores.text = "{No se encontraron autores para este libro}"
        by_statement.text = ""
        cover.image = UIImage(named: "image1")
        
        titulo.sizeToFit()
        autores.sizeToFit()
        by_statement.sizeToFit()
        
        titulo.textColor = UIColor.lightGrayColor()
        autores.textColor = UIColor.lightGrayColor()
        
        titulo.hidden = true
        autores.hidden = true
        by_statement.hidden = true
        cover.hidden = true
    }
    
    func initializeTextFields() {
        isbnTextField.delegate = self
        isbnTextField.keyboardType = UIKeyboardType.NumbersAndPunctuation

    }

    
}

