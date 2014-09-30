var changeFontSize = function(size) {
    var body = document.getElementById("body")
    body.style.fontSize = size;
};

var changeColor = function(foreColor, backColor) {
    var body = document.getElementById("body")
    body.style.backgroundColor = backColor;
    body.style.color = foreColor;
};

var clearElementStyleByTagName = function(name, specific) {
    var all = document.getElementsByTagName(name);
    for (var i=0, max=all.length; i < max; i++) {
        if(specific) {
            all[i].style.backgroundColor = "";
            all[i].style.fontFamily = "";
            all[i].style.fontSize = "";
            all[i].style.padding = "";
            all[i].style.margin = "";
            all[i].style.lineHeight = "";
            all[i].style.position = "";
            all[i].style.zIndex = "";
            all[i].style.width = "";
            all[i].style.height = "";
        } else {
            all[i].removeAttribute("style");
        }
    }
};

var imageClicked = function(index) {
    var iframe = document.createElement('iframe');
    iframe.setAttribute('src', 'image:' + index);
    
    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
};

$(document).ready(function() {
    clearElementStyleByTagName("span");
    clearElementStyleByTagName("img");
    clearElementStyleByTagName("strong");
    clearElementStyleByTagName("br");
    clearElementStyleByTagName("h1");
    clearElementStyleByTagName("div", true);
    clearElementStyleByTagName("p", true);
                  
    $("img").click(function() {
        var index = $("img").index(this);
        imageClicked(index);
        return false;
    });
});
