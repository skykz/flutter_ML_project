
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_ai/resources/widgets/bounce_button.dart';

import '../common.dart';

  
class FeedBackScreen extends StatefulWidget{
  @override
  _FeedBackScreenState createState() => _FeedBackScreenState();
}

class _FeedBackScreenState extends State<FeedBackScreen> {
  final TextEditingController _textEditingControllerName = TextEditingController();

  final TextEditingController _textEditingControllerText = TextEditingController();

  final TextEditingController _textEditingControllerEmail = TextEditingController();

  bool isLoading = false;

 @override
  Widget build(BuildContext context) {
        
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(      
          body: CustomScrollView(
              slivers: <Widget>[
                _buildAppBar(context, statusBarHeight),            
                _buildBody(context, statusBarHeight),                
          ],
        ),   
    );
  }

  final databaseReference = 
    Firestore.instance;

  Future<String> createRecord(String name,String email, String message) async {   
    DocumentReference ref = await databaseReference.collection("feedbacks")
        .add({
          'name': name,
          'email почта':email,
          'message': message,
          'create_date':DateTime.now()
        }).catchError((onError){
          print("++++++++++++++ $onError");
        });

    print(ref.documentID);
    return ref.documentID;
  }

  Widget _buildAppBar(BuildContext context, double statusBarHeight,) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 50,    
      backgroundColor: Colors.black,
      title: Text("Напишите нам ",style: TextStyle(
        color: Colors.white 
      ),),      
      iconTheme: IconThemeData(
        color: Colors.white
      ),        
      shape: ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50))),      
    );
 
  }

  Widget _buildBody(BuildContext context, double statusBarHeight) {
      final EdgeInsets mediaPadding = MediaQuery.of(context).padding;
      final EdgeInsets padding = EdgeInsets.only(
        top: 0.0,
        left: 10.0 + mediaPadding.left,
        right: 10.0 + mediaPadding.right,
        bottom: 0.0,
      );               
        return SliverPadding(
          padding: padding,
          sliver: SliverList(                             
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {

                  return  Padding(padding: EdgeInsets.all(15.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[                                           
                          SizedBox(
                            height: 10,
                          ),
                          Padding(padding: EdgeInsets.all(5.0),child:Text("Ваше имя: ")),
                          Container(
                          width: 200,
                          decoration: BoxDecoration(
                              color:Colors.deepOrange[50],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          child: Scrollbar(                  
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              reverse: true,
                              child: TextField(
                                controller: _textEditingControllerName,
                                maxLines: null,
                                maxLength: 35,
                                cursorWidth: 3.0,
                                onChanged: (value) {
                                  value.trim();
                                },
                                cursorColor:Colors.deepOrange,                      
                                decoration: InputDecoration(
                                    hintText: "Имя",                                  
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 10.0),
                                    border: InputBorder.none),
                              ),
                        ),
                      )),
                      SizedBox(height: 10.0,),
                      Padding(padding: EdgeInsets.all(5.0),child:Text("Ваша почта: ",)),
                      Container(
                          width: 250,                  
                          decoration: BoxDecoration(
                              color:Colors.deepOrange[50],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          child: Scrollbar(                    
                            child: SingleChildScrollView(                      
                              scrollDirection: Axis.vertical,                              
                              reverse: true,
                          child: TextField(
                            controller: _textEditingControllerEmail,
                            maxLines: null,                    
                            cursorWidth: 3.0,             
                            keyboardType: TextInputType.emailAddress,                            
                            maxLength: 100,                                                 
                            onChanged: (value) {
                              value.trim();
                            },
                            cursorColor:Colors.deepOrange,
                            decoration: InputDecoration(
                                hintText: "e-mail почта",                                  
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 10.0),
                                border: InputBorder.none),
                          ),
                        ),
                      )),
                      SizedBox(
                        height: 10,
                      ),
                      Padding(padding: EdgeInsets.all(5.0),child:Text("Ваш текст: ",)),
                      Container(
                          width: 500,                  
                          decoration: BoxDecoration(
                             color:Colors.deepOrange[50],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          child: Scrollbar(                    
                            child: SingleChildScrollView(                      
                              scrollDirection: Axis.vertical,
                              padding: EdgeInsets.only(bottom: 20),
                              reverse: true,
                          child: TextField(
                            controller: _textEditingControllerText,
                            maxLines: null,                    
                            cursorWidth: 3.0,                                            
                            maxLength: 200,    
                            onChanged: (value) {
                              value.trim();
                            },
                            cursorColor:Colors.deepOrange,
                            decoration: InputDecoration(
                                hintText: "описание ",     
                                fillColor: Colors.purple,                             
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 10.0),
                                border: InputBorder.none),
                          ),
                        ),
                      )),
                   SizedBox(height: 20,), 
                   _builsSendButton(context),                                                                        
                ],
              ),);                     
              },              
              childCount: 1,
              addAutomaticKeepAlives: true,            
            ),
          ),
        );                 
       
  }

  Center _builsSendButton(BuildContext context){
    return  Center(                
                child:Builder(
                    builder: (ctx) => PrimaryButton(
                        buttonText: "Отправить",
                        height: 50,                                                            
                        width: 200,                 
                        isOrderCreating: isLoading,       
                        colorButton: Colors.orange[400],
                        onPressed: ()=> sendMessage(ctx))));
  }


  Future<dynamic> sendMessage(BuildContext contextIn) async {

    if ((_textEditingControllerName.text.trim() != '') && (_textEditingControllerText.text.trim() != '') && (_textEditingControllerEmail.text.trim() != '')) {      
      String name = _textEditingControllerName.text;
      String email = _textEditingControllerEmail.text;
      String message = _textEditingControllerText.text;

      if (validateEmail(email) == "true"){
      _textEditingControllerName.clear();
      _textEditingControllerText.clear();       
      _textEditingControllerEmail.clear();        
      
      setState(() {
        isLoading = true;
      });

      return createRecord(
        name,email,message
      ).then((onValue){
          if(onValue != null){
            if(this.mounted)
            setState(() {
              isLoading = false;
            });
           showCustomSnackBar(contextIn, 
            "Успешно отправлено!",
                Colors.green,Icons.check_circle_outline);        
          }
          
      }).catchError((onError){
        showCustomSnackBar(contextIn, 
            "Ошибка при отправке!",
              Colors.red,Icons.info_outline);        
      });     
    }
      showCustomSnackBar(contextIn, 
            "Введите E-mail почту!",
              Colors.red,Icons.info_outline);        
    } else {
      showCustomSnackBar(contextIn, 
      "Заполните все поля!",Colors.red,
        Icons.info_outline);
    }
  }
}