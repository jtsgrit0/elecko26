// 조사 방법 추가
var methodCnt = 1;

$("button.btn.h_xs.line02.ico.print").click(function(){
    window.print();
});

// 이벤트 발생
function initEvent(){
	jQuery(document).on('focusin','.dateType',function(e){
		$(this).datepicker({
			maxDate:0
		});
	});

	$(".object_mothod1, .object_mothod2, .object_mothod3, .object_mothod4, .object_mothod5").keyup(function(){
		jf_objectMethodCal();
	});

	$(".sampleSexSize, .sampleAgeSize, .sampleSexSize2").keyup(function(i){
		
		if($(this).is(".sampleSexSize")){
			jf_sampleSizeCal("sampleSexSize");
		}else if($(this).is(".sampleSexSize2")){
			jf_sampleSizeCal("sampleSexSize2");
		}else{
			jf_sampleSizeCal("sampleAgeSize");
		}
	});

}

// 초기값 있을 경우
function initVal(){

	//조사일시
	if($("#pollDate").val() != ""){
		var pd = $("#pollDate").val().split("/");
		for(var i=1;i<pd.length;i++){
			jf_pollDateAdd();
		}

		for(var i=0;i<pd.length;i++){
			var v = pd[i].split(".");
			var d;
			var s;
			var s2;
			var e;
			var e2;

			if(v[3] != null)
			{
				d = v[0];
				s = v[1];
				s2 = v[2];
				e = v[3];
				e2 = v[4];
			}
			else
			{
				d = v[0];
				s = v[1];
				s2 = '00';
				e = v[2];
				e2 = '00';
			}


			$(".pollDate").eq(i).val(d);
			$(".pollDate_sHour").eq(i).val(s);
			$(".pollDate_s2Minute").eq(i).val(s2);
			$(".pollDate_eHour").eq(i).val(e);
			$(".pollDate_e2Minute").eq(i).val(e2);
			
			if(i == 0){
			//select 선택 S 
				$("label#startHour").text($(".pollDate_sHour option:selected").eq(i).val());
				$("label#startMinute").text($(".pollDate_s2Minute option:selected").eq(i).val());
				$("label#endHour").text($(".pollDate_eHour option:selected").eq(i).val());
				$("label#endMinute").text($(".pollDate_e2Minute option:selected").eq(i).val());
				
			}else{
				$("label#hourLabel").eq(i-1).text($(".pollDate_sHour option:selected").eq(i).val());
				$("label#minuteLabel").eq(i-1).text($(".pollDate_s2Minute option:selected").eq(i).val());
				$("label#ehourLabel").eq(i-1).text($(".pollDate_eHour option:selected").eq(i).val());
				$("label#e2MinuteLabel").eq(i-1).text($(".pollDate_e2Minute option:selected").eq(i).val());
			}
			//select 선택 E
		}
	}
	
	//조사시간 세팅
	pollHourCalc();
	
	if($("#pollMethod21").val() != ""){
		/*$('#ADDtable1').css("display", "block");*/
		
		methodCnt = 2;
	}

	if($("#pollMethod31").val() != ""){
		/*$('#ADDtable2').css("display", "block");*/
		
		methodCnt = 3;
	}

	if($("#pollMethod41").val() != ""){
		/*$('#ADDtable3').css("display", "block");*/
		
		methodCnt = 4;
	}

	if($("#pollMethod51").val() != ""){
		/*$('#ADDtable4').css("display", "block");*/
		
		methodCnt = 5;
	}

	// 성별
	if($("#sampleSexSize").val() != ""){

		jf_sampleSizeCal("sampleSexSize");
	}
	// 나이
	if($("#sampleAgeSize").val() != ""){

		jf_sampleSizeCal("sampleAgeSize");
	}
	//피조사자 접촉현황
	jf_objectMethodCal();


	if($("#fileType").val() != ""){
		var obj = $("#fileType").val().split(",");
		$(".fileType").each(function(i){
			for(var i=0;i<obj.length;i++){
				if($(this).val() == obj[i]){
					$(this).attr("checked",true);
				}
			}
		});
	}
	if($("#pollViewDate").val() != ""){
		var temp = $("#pollViewDate").val().split(" ");
		if(temp != null && temp.length == 2){
			var date = temp[0];
			var time = temp[1].split(":");
			var hour = time[0];
			var min = time[1];
			$("#pollViewDD").val(date);
			$("#pollViewHour").val(hour);
			$("#pollViewMin").val(min);
		}
	}

}

//조사시간 더하기 + 조사일수 세팅 (reg.jsp)
function pollHourCalc() {
	var stime = 0;
	var etime = 0;
	$(".pollDate_eHour").each(function(i,eHour) {
		etime += Number(eHour.value) * 60;
		
	});
	$(".pollDate_sHour").each(function(i,sHour) {
		stime += Number(sHour.value) * 60;
	});

	
	$(".pollDate_s2Minute").each(function(i,min) {
		stime += Number(min.value);
	});
	$(".pollDate_e2Minute").each(function(i,min) {
		etime += Number(min.value);
	});

	var time = etime - stime;
	if(time > 0 ){
		var h = parseInt (time/60);
		var m = parseInt (time%60);
		$('#totalHour').text(h+"시간"+pad(m,2)+"분");
	}
	
	var a = {};
	var jbAry = new Array();
	for(var i=0 ; i<$(".pollDate").size()-1 ; i++){
		var d = $(".pollDate").eq(i).val();
		jbAry[i] = d;
	}
	
	for (var i = 0; i < jbAry.length; i++) {
        if (typeof a[jbAry[i]] == 'undefined') {
            a[jbAry[i]] = 1;
        }
    }
	
	jbAry.length = 0;
    for (var i in a) {
    	jbAry[jbAry.length] = i;
    }
    
    $('#totalDay').text(jbAry.length +"일");
}

// 결과값 부분
function jf_sampleSizeCal(className){
	
	var sum = 0;
	$("."+className).each(function(){
		var val = $(this).val().replace(/[^0-9]/gi,'');
		$(this).val(val);
		if(val != null && val != ""){
			sum += parseInt(val);
		}
	});
	if(className == 'sampleSexSize' || className == 'sampleSexSize2'){		
		$("#"+className+"Sum").text(sum);
	}
	var men1 = $("#sampleSexMen1").val();
	
	var women1 = $("#sampleSexWoman1").val();
	if(men1 > 0)
	{
		
	}
	else
	{
		men1 = 0;
	}
	if(women1 > 0)
	{
		
	}
	else
	{
		women1 = 0;
	}
	var percent = 1.96*Math.sqrt(0.25/(parseInt(women1) + parseInt(men1)))*100;
	
	$("#sampleErrorp").val(percent.toFixed(1));
	
	return sum;
}

//피조사자 접촉현황
function jf_objectMethodCal(){
	var avrCount = 0;
	// 조사방법1
	var rate19 = $(".object_mothod1").eq(0).val().replace(/[^0-9]/gi,'');
	var rate10 = $(".object_mothod1").eq(1).val().replace(/[^0-9]/gi,'');
	var rate11 = $(".object_mothod1").eq(2).val().replace(/[^0-9]/gi,'');
	var rate12 = $(".object_mothod1").eq(3).val().replace(/[^0-9]/gi,'');
	var rate13 = $(".object_mothod1").eq(4).val().replace(/[^0-9]/gi,'');

	if(rate19 == null || rate19 == ""){
		rate19 = 0;
	}else{
		rate19 =  parseInt(rate19);
	}
	if(rate10 == null || rate10 == ""){
		rate10 = 0;
	}else{
		rate10 =  parseInt(rate10);
	}
	if(rate11 == null || rate11 == ""){
		rate11 = 0;
	}else{
		rate11 =  parseInt(rate11);
	}
	if(rate12 == null || rate12 == ""){
		rate12 = 0;
	}else{
		rate12 =  parseInt(rate12);
	}
	if(rate13 == null || rate13 == ""){
		rate13 = 0;
	}else{
		rate13 =  parseInt(rate13);
	}
	var avr1 = rate13/(rate12+rate13)*100;
	var sum1 = parseInt(rate19) + parseInt(rate10) + parseInt(rate11) + parseInt(rate12) + parseInt(rate13) ;
	$("#object_mothod1Sum").text(sum1);
	if(avr1 > 0){
		$(".object_mothod1").eq(5).val(avr1.toFixed(1));
		avrCount +=1;
	}else{
		$(".object_mothod1").eq(5).val(0);
	}

	// 조사방법2
	var rate29 = $(".object_mothod2").eq(0).val();
	var rate20 = $(".object_mothod2").eq(1).val();
	var rate21 = $(".object_mothod2").eq(2).val();
	var rate22 = $(".object_mothod2").eq(3).val();
	var rate23 = $(".object_mothod2").eq(4).val();
	if(rate29 == null || rate29 == ""){
		rate29 = 0;
	}else{
		rate29 =  parseInt(rate29);
	}
	if(rate20 == null || rate20 == ""){
		rate20 = 0;
	}else{
		rate20 =  parseInt(rate20);
	}
	if(rate21 == null || rate21 == ""){
		rate21 = 0;
	}else{
		rate21 =  parseInt(rate21);
	}
	if(rate22 == null || rate22 == ""){
		rate22 = 0;
	}else{
		rate22 =  parseInt(rate22);
	}
	if(rate23 == null || rate23 == ""){
		rate23 = 0;
	}else{
		rate23 =  parseInt(rate23);
	}
	var avr2 = rate23/(rate22+rate23)*100;
	var sum2 = parseInt(rate29) + parseInt(rate20) + parseInt(rate21) + parseInt(rate22) + parseInt(rate23) ;
	$("#object_mothod2Sum").text(sum2);
	if(avr2 > 0){
		$(".object_mothod2").eq(5).val(avr2.toFixed(1));
		avrCount +=1;
	}else{
		$(".object_mothod2").eq(5).val(0);
	}

	// 조사방법3
	var rate39 = $(".object_mothod3").eq(0).val();
	var rate30 = $(".object_mothod3").eq(1).val();
	var rate31 = $(".object_mothod3").eq(2).val();
	var rate32 = $(".object_mothod3").eq(3).val();
	var rate33 = $(".object_mothod3").eq(4).val();
	if(rate39 == null || rate39 == ""){
		rate39 = 0;
	}else{
		rate39 =  parseInt(rate39);
	}
	if(rate30 == null || rate30 == ""){
		rate30 = 0;
	}else{
		rate30 =  parseInt(rate30);
	}
	if(rate31 == null || rate31 == ""){
		rate31 = 0;
	}else{
		rate31 =  parseInt(rate31);
	}
	if(rate32 == null || rate32 == ""){
		rate32 = 0;
	}else{
		rate32 =  parseInt(rate32);
	}
	if(rate33 == null || rate33 == ""){
		rate33 = 0;
	}else{
		rate33 =  parseInt(rate33);
	}
	var avr3 = rate33/(rate32+rate33)*100;

	var sum3 = parseInt(rate39) + parseInt(rate30) + parseInt(rate31) + parseInt(rate32) + parseInt(rate33) ;
	$("#object_mothod3Sum").text(sum3);
	if(avr3 > 0){
		$(".object_mothod3").eq(5).val(avr3.toFixed(1));
		avrCount +=1;
	}else{
		$(".object_mothod3").eq(5).val(0);
	}



	// 조사방법4
	var rate49 = $(".object_mothod4").eq(0).val();
	var rate40 = $(".object_mothod4").eq(1).val();
	var rate41 = $(".object_mothod4").eq(2).val();
	var rate42 = $(".object_mothod4").eq(3).val();
	var rate43 = $(".object_mothod4").eq(4).val();
	if(rate49 == null || rate49 == ""){
		rate49 = 0;
	}else{
		rate49 =  parseInt(rate49);
	}
	if(rate40 == null || rate40 == ""){
		rate40 = 0;
	}else{
		rate40 =  parseInt(rate40);
	}
	if(rate41 == null || rate41 == ""){
		rate41 = 0;
	}else{
		rate41 =  parseInt(rate41);
	}
	if(rate42 == null || rate42 == ""){
		rate42 = 0;
	}else{
		rate42 =  parseInt(rate42);
	}
	if(rate43 == null || rate43 == ""){
		rate43 = 0;
	}else{
		rate43 =  parseInt(rate43);
	}
	var avr4 = rate43/(rate42+rate43)*100;
	var sum4 = parseInt(rate49) + parseInt(rate40) + parseInt(rate41) + parseInt(rate42) + parseInt(rate43) ;
	$("#object_mothod4Sum").text(sum4);
	if(avr4 > 0){
		$(".object_mothod4").eq(5).val(avr4.toFixed(1));
		avrCount +=1;
	}else{
		$(".object_mothod4").eq(5).val(0);
	}

	// 조사방법5
	var rate59 = $(".object_mothod5").eq(0).val();
	var rate50 = $(".object_mothod5").eq(1).val();
	var rate51 = $(".object_mothod5").eq(2).val();
	var rate52 = $(".object_mothod5").eq(3).val();
	var rate53 = $(".object_mothod5").eq(4).val();
	if(rate59 == null || rate59 == ""){
		rate59 = 0;
	}else{
		rate59 =  parseInt(rate59);
	}
	if(rate50 == null || rate50 == ""){
		rate50 = 0;
	}else{
		rate50 =  parseInt(rate50);
	}
	if(rate51 == null || rate51 == ""){
		rate51 = 0;
	}else{
		rate51 =  parseInt(rate51);
	}
	if(rate52 == null || rate52 == ""){
		rate52 = 0;
	}else{
		rate52 =  parseInt(rate52);
	}
	if(rate53 == null || rate53 == ""){
		rate53 = 0;
	}else{
		rate53 =  parseInt(rate53);
	}
	var avr5 = rate53/(rate52+rate53)*100;
	var sum5 = parseInt(rate59) + parseInt(rate50) + parseInt(rate51) + parseInt(rate52) + parseInt(rate53) ;
	$("#object_mothod5Sum").text(sum5);
	if(avr5 > 0){
		$(".object_mothod5").eq(5).val(avr5.toFixed(1));
		avrCount +=1;
	}else{
		$(".object_mothod5").eq(5).val(0);
	}

	var  avrsum = parseFloat( $(".object_mothod1").eq(5).val()) + parseInt($(".object_mothod2").eq(5).val()) + parseInt($(".object_mothod3").eq(5).val())
				+ parseInt($(".object_mothod4").eq(5).val()) + parseInt($(".object_mothod5").eq(5).val()) ;

	var  TotalAVR =  avrsum / avrCount;

	var sumAB = rate12 + rate13 + rate22 + rate23 + rate32 + rate33 + rate42 + rate43 + rate52 + rate53;
	var sumB = rate13 + rate23 + rate33 + rate43 + rate53 ;

	if(sumAB > 0){
		var sumAVR =  (sumB / sumAB ) * 100;
		$("#object_mothodtOTALavr").text(sumAVR.toFixed(1));
	}else{
		$("#object_mothodtOTALavr").text(0);
	}
	
	//합계
	$("#object_mothod1Sum").val(sum1);
	$("#object_mothod2Sum").val(sum2);
	$("#object_mothod3Sum").val(sum3);
	$("#object_mothod4Sum").val(sum4);
	$("#object_mothod5Sum").val(sum5);

	//접촉 후 거절 및 중도 이탈 사례수 (A) 합계
	$("#ATotalSum").html(
			parseInt($("#pollObjectMethod13").val() != "" ? $("#pollObjectMethod13").val() : "0")+
			parseInt($("#pollObjectMethod23").val() != "" ? $("#pollObjectMethod23").val() : "0")+ 
			parseInt($("#pollObjectMethod33").val() != "" ? $("#pollObjectMethod33").val() : "0")+
			parseInt($("#pollObjectMethod43").val() != "" ? $("#pollObjectMethod43").val() : "0")+
			parseInt($("#pollObjectMethod53").val() != "" ? $("#pollObjectMethod53").val() : "0") 
			);
	
	//접촉 후 응답완료 사례수 (B) 합계
	$("#BTotalSum").html(
			parseInt($("#pollObjectMethod14").val() != "" ? $("#pollObjectMethod14").val() : "0")+
			parseInt($("#pollObjectMethod24").val() != "" ? $("#pollObjectMethod24").val() : "0")+ 
			parseInt($("#pollObjectMethod34").val() != "" ? $("#pollObjectMethod34").val() : "0")+
			parseInt($("#pollObjectMethod44").val() != "" ? $("#pollObjectMethod44").val() : "0")+
			parseInt($("#pollObjectMethod54").val() != "" ? $("#pollObjectMethod54").val() : "0") 
			);
	//전체합계
	$("#totalSum").html(
			parseInt($("#object_mothod1Sum").val() != "" ? $("#object_mothod1Sum").val() : "0")+
			parseInt($("#object_mothod2Sum").val() != "" ? $("#object_mothod2Sum").val() : "0")+ 
			parseInt($("#object_mothod3Sum").val() != "" ? $("#object_mothod3Sum").val() : "0")+
			parseInt($("#object_mothod4Sum").val() != "" ? $("#object_mothod4Sum").val() : "0")+
			parseInt($("#object_mothod5Sum").val() != "" ? $("#object_mothod5Sum").val() : "0")
			);
	
}
// 피조사자 접촉현황

var pollDateDivCnt = 0;
// 조사 일시 날짜 추가
function jf_pollDateAdd(){
	var html = $("#pollDate_html").html();
	$("#pollDate_div").append(html);
	
	var startHourSize = $(".pollDate_sHour").size();
	//시작 시간 select 선택
	$(".pollDate_sHour").eq(startHourSize-2).on("change", function(){
		for ( var cnt = 0; cnt < $("label#hourLabel").length; cnt++) {
			if (cnt == startHourSize-2) {
				$("label#hourLabel").eq(cnt-1).val($(".pollDate_sHour option:selected").eq(startHourSize-2).val());
				$("label#hourLabel").eq(cnt-1).text($(".pollDate_sHour option:selected").eq(startHourSize-2).val());
				$("#pollDate_sHour option").eq(0).removeAttr('selected').filter('[value='+$(".pollDate_sHour option:selected").eq(cnt-1).val()+']').attr('selected', true).change();
				$("#pollDate_sHour").eq(startHourSize-2).val($(".pollDate_sHour option:selected").eq(startHourSize-2).val()).attr("selected", "selected").change();
			}
		}
	});
	
	var startMinSize = $(".pollDate_s2Minute").size();
	//시작 분 select 선택
	$(".pollDate_s2Minute").eq(startMinSize-2).on("change", function(){
		for ( var cnt = 0; cnt < $("label#minuteLabel").length; cnt++) {
			if (cnt == startMinSize-2) {
				$("label#minuteLabel").eq(cnt-1).val($(".pollDate_s2Minute option:selected").eq(startMinSize-2).val());
				$("label#minuteLabel").eq(cnt-1).text($(".pollDate_s2Minute option:selected").eq(startMinSize-2).val());
				$("#pollDate_s2Minute option").eq(0).removeAttr('selected').filter('[value='+$(".pollDate_s2Minute option:selected").eq(cnt-1).val()+']').attr('selected', true).change();
				$("#pollDate_s2Minute").eq(startMinSize-2).val($(".pollDate_s2Minute option:selected").eq(startMinSize-2).val()).attr("selected", "selected").change();
			}
		}
	});
	
	var endHourSize = $(".pollDate_eHour").size();
	//끝 시간 select 선택
	$(".pollDate_eHour").eq(endHourSize-2).on("change", function(){
		for ( var cnt = 0; cnt < $("label#ehourLabel").length; cnt++) {
			if (cnt == endHourSize-2) {
				$("label#ehourLabel").eq(cnt-1).val($(".pollDate_eHour option:selected").eq(endHourSize-2).val());
				$("label#ehourLabel").eq(cnt-1).text($(".pollDate_eHour option:selected").eq(endHourSize-2).val());
				$("#pollDate_eHour option").eq(0).removeAttr('selected').filter('[value='+$(".pollDate_eHour option:selected").eq(cnt-1).val()+']').attr('selected', true).change();
				$("#pollDate_eHour").eq(endHourSize-2).val($(".pollDate_eHour option:selected").eq(endHourSize-2).val()).attr("selected", "selected").change();
			}
		}
	});
	
	var endMinSize = $(".pollDate_eHour").size();
	//끝 뿐 select 선택
	$(".pollDate_e2Minute").eq(endMinSize-2).on("change", function(){
		for ( var cnt = 0; cnt < $("label#e2MinuteLabel").length; cnt++) {
			if (cnt == endMinSize-2) {
				$("label#e2MinuteLabel").eq(cnt-1).val($(".pollDate_e2Minute option:selected").eq(endMinSize-2).val());
				$("label#e2MinuteLabel").eq(cnt-1).text($(".pollDate_e2Minute option:selected").eq(endMinSize-2).val());
				$("#pollDate_e2Minute option").eq(0).removeAttr('selected').filter('[value='+$(".pollDate_e2Minute option:selected").eq(cnt-1).val()+']').attr('selected', true).change();
				$("#pollDate_e2Minute").eq(endMinSize-2).val($(".pollDate_e2Minute option:selected").eq(endMinSize-2).val()).attr("selected", "selected").change();
			}
		}
	});
	
}

//조사 일시 날짜 삭제
function jf_pollDateDelete(obj){
	$(obj).parent().remove();
	pollHourCalc();
}

//조사 방법 삭제
function jf_serveyTypeDelete(){

	if (methodCnt < 2){
		alert("최소 하나는 입력하여야 합니다.");
		return false;
	}else{
		if(methodCnt == 2){
			$("#object_mothod2Sum").text("0");
			$('#ADDtable1').css("display", "none").find(":input").val("");
			$('#ADDtable1 select.step1').change();
			$('#taptSpan2').hide();
			if(tabNumber == '2'){
				tabNumber--;
				$('.set1').show();
			}
		}else if(methodCnt == 3){
			$("#object_mothod3Sum").text("0");
			$('#ADDtable2').css("display", "none").find(":input").val("");
			$('#ADDtable2 select.step1').change();
			$('#taptSpan3').hide();
			if(tabNumber == '3'){
				tabNumber--;
				$('.set2').show();
			}
		}else if(methodCnt == 4){
			$("#object_mothod4Sum").text("0");
			$('#ADDtable3').css("display", "none").find(":input").val("");
			$('#ADDtable3 select.step1').change();
			$('#taptSpan4').hide();
			if(tabNumber == '4'){
				tabNumber--;
				$('.set3').show();
			}
		}else if(methodCnt == 5){
			$("#object_mothod5Sum").text("0");
			$('#ADDtable4').css("display", "none").find(":input").val("");
			$('#ADDtable4 select.step1').change();
			$('#taptSpan5').hide();
			if(tabNumber == '5'){
				tabNumber--;
				$('.set4').show();
			}
		}
	}
	jf_objectMethodCal();
	methodCnt -= 1;
}

function resizePollMethod(){

	$(".roopTables table").css("width", 100/methodCnt+"%");
}
	
function isNum(){
	
    var key;
    var e = event || window.event; 

    if(window.event)
         key = window.event.keyCode; //IE
    else
         key = e.which; //firefox

    // backspace or delete or tab
    if (key == 0 || key == 8 || key == 46 || key == 9){
        if (typeof e.stopPropagation != "undefined") {
            e.stopPropagation();
        } else {
            e.cancelBubble = true;
        }   
        return ;
    }

   if(!(key==8||key==9||key==13||key==46||key==144||(key>=48&&key<=57)||key==110||key==190||key==37||key==38||key==39||key==40)){
        alert('숫자만 입력 가능합니다');
        if(e.preventDefault)
        	e.preventDefault();
        else 
        	e.returnValue = false;
   }
}