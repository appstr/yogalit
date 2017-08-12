// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require ahoy
//= require jquery_ujs
//  require turbolinks
//= require_tree .

ahoy.trackAll();

$(document).ready(function(){
  $('select').material_select();
  $('.modal').modal();
});

function isNumber(evt) {
  evt = (evt) ? evt : window.event;
  var charCode = (evt.which) ? evt.which : evt.keyCode;
  if (charCode > 31 && (charCode < 48 || charCode > 57)) {
      return false;
  }
  return true;
}

function isChar(evt) {
  evt = (evt) ? evt : window.event;
  var charCode = (evt.which) ? evt.which : evt.keyCode;
  if ((charCode < 65 || charCode > 122) ) {
      return false;
  }
  else if (charCode > 90 && charCode < 97) {
    return false;
  }
  else {
    return true;
  }
}

function clickedSidebar(l){
  $(".sidebar_option_div").css("background-color", "#1c1b1b");
  $("#"+l.id).css("background-color", "#16e0bd");
  $(".dashboard_content").hide();
  $("."+l.id).show();
}

function dashboardWelcome(){
  $(".sidebar_option_div").css("background-color", "#1c1b1b");
  $(".dashboard_content").hide();
  $(".dashboard_welcome").show();
}

function changeDuration(){
  var val = $("#duration").val();
  $("#time_range_select").find("li").remove();
  $("#time_frame").find("option").remove();
  var requestData = {"duration": val, "new_date_request": true};
  var url = "/switch_time_frame";
  var request = $.ajax({
    method: "GET",
    url: url,
    data: requestData,
    success: function(result){
      var selectValues = result.available_times;
      if(selectValues.length > 0){
        var length = selectValues.length;
        for(var i = 0; length > i; i++){
          $("#time_range_select").find("ul").append('<li onclick="timeRangeActiveOption(this);" value='+selectValues[i][1]+'><span>'+selectValues[i][0]+'</span></li>');
          $("#time_frame").append('<option value="'+selectValues[i][1]+'">'+selectValues[i][0]+'</option>');
        }
      }
      $('#time_frame').material_select();
    }
  });
}

function timeRangeActiveOption(l){
  $("#time_range_select").find("li").removeClass("active");
  $(l).toggleClass("active selected");
  $("#time_frame").val(l.value);
  $('#time_frame').material_select();
}

function paymentTypeChoice(l){
  $(".payment_div").hide();
  $(".initial_payment_div").hide();
  $("."+l.value+"_div").show();
}

function registeredBusinessChoice(l){
  if(l.value == "true"){
    $(".registered_business_div").show();
  }else{
    $(".registered_business_div").hide();
  }
  $(".initial_registered_business_div").hide();
}
