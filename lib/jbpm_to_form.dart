library jbpm_json_to_form;

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class JbpmForm extends StatefulWidget {
  final String form;
  final Map formMap;
  final double padding;
  final Map errorMessages;
  final Widget buttonSave;
  final Map decorations;
  final Function actionSave;
  final Function downloadFile;
  final ValueChanged<dynamic> onChanged;

  const JbpmForm({
    @required this.form,
    @required this.onChanged,
    this.formMap,
    this.padding,
    this.errorMessages = const {},
    this.decorations = const {},
    this.buttonSave,
    this.downloadFile,
    this.actionSave,
  });

  @override
  _JbpmFormState createState() => _JbpmFormState(formMap ?? json.decode(form));
}

class _JbpmFormState extends State<JbpmForm> {
  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = true;
  bool _hasValidMime = false;
  FileType _pickingType;

  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  // Map
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  Position _currentPosition;
  String _currentAddress;

  @override
  void initState() {
    super.initState();

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        print('position: $position');
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      final coordinates = new Coordinates(
          _currentPosition.latitude, _currentPosition.longitude);
      var addresses =
          await Geocoder.local.findAddressesFromCoordinates(coordinates);
      var first = addresses.first;

      setState(() {
        _currentAddress = "${first.addressLine} ";
        print('my current location is $_currentAddress');
      });
    } catch (e) {
      print(e);
    }
  }

  final dynamic formGeneral;

  String radioValue;

  String isRequired(item, value) {
    if (value.isEmpty) {
      return widget.errorMessages[item['name']] ??
          '${item['name']} cannot be empty';
    }
    return null;
  }

  String validateEmail(item, String value) {
    String p = "[a-zA-Z0-9\+\.\_\%\-\+]{1,256}" +
        "\\@" +
        "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" +
        "(" +
        "\\." +
        "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" +
        ")+";
    RegExp regExp = RegExp(p);

    if (regExp.hasMatch(value)) {
      return null;
    }
    return 'Email is not valid';
  }

  bool labelHidden(item) {
    if (item.containsKey('hiddenLabel')) {
      if (item['hiddenLabel'] is bool) {
        return !item['hiddenLabel'];
      }
    } else {
      return true;
    }
    return false;
  }

  List<Widget> jbpmToForm() {
    List<Widget> listWidget = List<Widget>();
    print('I got inside JBPM');
    for (var i = 0; i < formGeneral['fields'].length; i++) {
      Map item = formGeneral['fields'][i];

      if (item['code'] == 'TextBox' ||
          item['code'] == 'TextArea' ||
          item['code'] == 'IntegerBox') {
        String itemName = "${item['name']}";

        if (itemName != 'address') {
          listWidget.add(
            Container(
              margin: EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    onSaved: (val) {
                      var d = '';
                      setState(() => d = val);
                      print(d);
                    },
                    controller: null,
                    keyboardType: item['code'] == 'IntegerBox'
                        ? TextInputType.number
                        : TextInputType.text,
                    initialValue: formGeneral['fields'][i]['value'] ?? null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: item['label'],
                      hintText: item['placeHolder'],
                    ),
                    maxLength: item['maxLength'] ?? null,
                    maxLines: item['code'] == 'TextArea' ? 3 : 1,
                    onChanged: (String value) {
                      formGeneral['fields'][i]['value'] = value;
                      _handleChanged();
                    },
                    readOnly: item['readOnly'] ?? false,
                    obscureText: item['code'] == 'Password' ? true : false,
                    validator: (value) {
                      if (item['code'] == 'Email') {
                        return validateEmail(item, value);
                      }

                      if (item.containsKey('required')) {
                        if (item['required'] == true ||
                            item['required'] == 'True' ||
                            item['required'] == 'true') {
                          return isRequired(item, value);
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
        } else if (itemName == 'address' && item['readOnly']) {
          listWidget.add(
            Container(
              margin: EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    onSaved: (val) {
                      var d = '';
                      setState(() => d = val);
                      print(d);
                    },
                    controller: null,
                    keyboardType: item['code'] == 'IntegerBox'
                        ? TextInputType.number
                        : TextInputType.text,
                    initialValue: formGeneral['fields'][i]['value'] ?? null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: item['label'],
                      hintText: item['placeHolder'],
                    ),
                    maxLength: item['maxLength'] ?? null,
                    maxLines: item['code'] == 'TextArea' ? 3 : 1,
                    onChanged: (String value) {
                      formGeneral['fields'][i]['value'] = value;
                      _handleChanged();
                    },
                    readOnly: item['readOnly'] ?? false,
                    obscureText: item['code'] == 'Password' ? true : false,
                    validator: (value) {
                      if (item['code'] == 'Email') {
                        return validateEmail(item, value);
                      }

                      if (item.containsKey('required')) {
                        if (item['required'] == true ||
                            item['required'] == 'True' ||
                            item['required'] == 'true') {
                          return isRequired(item, value);
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          // Get device current location and display in a text field
          listWidget.add(
            Container(
              margin: EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_currentAddress != null)
                    TextFormField(
                      onSaved: (val) {
                        var d = '';
                        setState(() => d = val);
                        print(d);
                      },
                      controller: null,
                      keyboardType: item['code'] == 'IntegerBox'
                          ? TextInputType.number
                          : TextInputType.text,
                      initialValue: formGeneral['fields'][i]['value'] =
                          _currentAddress ?? null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: item['label'],
                        hintText: item['placeHolder'],
                      ),
                      maxLength: item['maxLength'] ?? null,
                      maxLines: item['code'] == 'TextArea' ? 2 : 1,
                      onChanged: (String value) {
                        formGeneral['fields'][i]['value'] = value;
                        _handleChanged();
                      },
                      readOnly: item['readOnly'] ?? false,
                      obscureText: item['code'] == 'Password' ? true : false,
                      validator: (value) {
                        if (item['code'] == 'Email') {
                          return validateEmail(item, value);
                        }

                        if (item.containsKey('required')) {
                          if (item['required'] == true ||
                              item['required'] == 'True' ||
                              item['required'] == 'true') {
                            return isRequired(item, value);
                          }
                        }
                        return null;
                      },
                    ),
                ],
              ),
            ),
          );
        }
      }

      if (item['code'] == 'CheckBox') {
        bool formValue = false;

        var val = formGeneral['fields'][i]['value'];

        if (item['value'] != null && (val != false && val != 'false')) {
          formValue = true;
        }
        List<Widget> checkboxes = [];
        if (labelHidden(item)) {
          checkboxes.add(Text(item['label'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)));
        }

        checkboxes.add(
          Row(
            children: <Widget>[
              Expanded(child: Text(formGeneral['fields'][i]['label'])),
              Checkbox(
                value: formValue,
                onChanged: (bool value) {
                  this.setState(
                    () {
                      formGeneral['fields'][i]['value'] = value;
                      _handleChanged();
                    },
                  );
                },
              ),
            ],
          ),
        );

        listWidget.add(
          Container(
            margin: EdgeInsets.only(top: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: checkboxes,
            ),
          ),
        );
      }

      if (item['code'] == 'RadioGroup') {
        listWidget.add(Container(
          margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
          child: Text(
            item['label'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
        ));

        radioValue = item['value'];
        for (var i = 0; i < item['options'].length; i++) {
          listWidget.add(Row(
            children: <Widget>[
              Expanded(child: Text(item['options'][i]['text'])),
              Radio<String>(
                  value: item['options'][i]['value'],
                  // this should be groupValue: radioValue,
                  groupValue: radioValue,
                  // groupValue: radioValue == null ? radioValue : radioValue,
                  onChanged: (String value) {
                    this.setState(() {
                      radioValue = value;
                      item['value'] = value;
                      _handleChanged();
                    });
                  }),
            ],
          ));
        }
      }

      if (item['code'] == 'ListBox') {
        Widget label = SizedBox.shrink();
        if (labelHidden(item)) {
          label = Text(
            item['label'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          );
        }
        listWidget.add(Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              label,
              DropdownButton<String>(
                hint: Text('Select option'),
                value: formGeneral['fields'][i]['value'],
                onChanged: (String newValue) {
                  setState(() {
                    formGeneral['fields'][i]['value'] = newValue;
                    _handleChanged();
                  });
                },
                items: item['options']
                    .map<DropdownMenuItem<String>>((dynamic data) {
                  return DropdownMenuItem<String>(
                      value: data['value'],
                      child: Text(
                        data['text'],
                        style: TextStyle(color: Colors.black),
                      ));
                }).toList(),
              )
            ],
          ),
        ));
      }

      if (item['code'] == 'Document' && item['readOnly'] == true) {
        listWidget.add(Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Column(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  var text = item['value'];
                  var newString = text.substring(text.length - 36);
                  widget.downloadFile(newString);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Text('  Click to Download Attachment'),
                    ),
                    Icon(
                      Icons.attach_file,
                      color: Colors.blue,
                      size: 24.0,
                      semanticLabel: 'Text to announce in accessibility modes',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }

      if (item['code'] == 'Document' && item['readOnly'] == false) {
        listWidget.add(Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RaisedButton(
                onPressed: () async {
                  setState(() => _loadingPath = true);
                  try {
                    _path = null;
                    _paths = await FilePicker.getMultiFilePath(
                        type: _pickingType, fileExtension: _extension);
                    formGeneral['fields'][i]['value'] = _paths;
                    _handleChanged();
                  } on PlatformException catch (e) {
                    print("Unsupported operation" + e.toString());
                  }
                  if (!mounted) return;
                  setState(() {
                    _loadingPath = false;
                    _fileName = _path != null
                        ? _path.split('/').last
                        : _paths != null ? _paths.keys.toString() : '...';
                  });
                  //  }
                },
                child: Text('Upload Document'),
              ),
              Builder(
                builder: (BuildContext context) => _loadingPath
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: const CircularProgressIndicator())
                    : _path != null || _paths != null
                        ? Container(
                            padding: const EdgeInsets.only(bottom: 30.0),
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: Scrollbar(
                                child: ListView.separated(
                              itemCount: _paths != null && _paths.isNotEmpty
                                  ? _paths.length
                                  : 1,
                              itemBuilder: (BuildContext context, int index) {
                                final bool isMultiPath =
                                    _paths != null && _paths.isNotEmpty;
                                final String name = 'File ${index + 1}: ' +
                                    (isMultiPath
                                        ? _paths.keys.toList()[index]
                                        : _fileName ?? '...');
                                final path = isMultiPath
                                    ? _paths.values.toList()[index].toString()
                                    : _path;

                                return (Container(
                                  child: Column(
                                    children: <Widget>[
                                      ListTile(
                                        title: Text(
                                          name,
                                        ),
                                        subtitle: Text(path),
                                      ),
                                    ],
                                  ),
                                ));
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      Divider(),
                            )),
                          )
                        : Container(),
              ),
            ],
          ),
        ));
      }
    }

    if (widget.buttonSave != null) {
      listWidget.add(
        Container(
          margin: EdgeInsets.only(top: 10.0),
          child: RoundedLoadingButton(
              color: Colors.green,
              child: widget.buttonSave,
              controller: _btnController,
              onPressed: () {
                _btnController.start();
                if (_formKey.currentState.validate()) {
                  Timer(Duration(seconds: 1), () {
                    widget.actionSave(formGeneral);
                  });
                }

                if (!_formKey.currentState.validate()) {
                  _btnController.stop();
                }

                Timer(Duration(seconds: 6), () {
                  _btnController.stop();
                });
              }),
        ),
      );
    }
    return listWidget;
  }

  _JbpmFormState(this.formGeneral);

  void _handleChanged() {
    widget.onChanged(formGeneral);
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    //  print(formGeneral);
    return Form(
      autovalidate: formGeneral['autoValidated'] ?? false,
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(widget.padding ?? 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: jbpmToForm(),
        ),
      ),
    );
  }
}
