function init(){
   	var socket = io();

   	$('form').submit(function(){
   		socket.emit('song', $('.inputMessage').val());
   		return false;
   	});
}
