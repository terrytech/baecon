function Entity(x,y,id){
  this.x = x;
  this.y = y;
  this.id = id;
  this.el = null;
  this.color = randomColor();
}

Entity.prototype.html= function (){
  return "<div class='entity animated' style='left:"+this.x+"%; top : "+this.y+"%; background-color :" + this.color +"'></div>"
}

Entity.prototype.move = function(x,y){
  this.x = x;
  this.y = y;

  this.el.css('left',this.x+'%');
  this.el.css('top',this.y+'%');

}

function Map(){
  this.entities = [];
}

Map.prototype.render = function(){
  this.entities.forEach(function(entity){
    var entityhtml = entity.html();
    entity.el = $(entityhtml);
    entity.el.addClass("bounceIn");
    $("#map").append(entity.el);
  })
}

Map.prototype.addEntity = function(entity){
  this.entities.push(entity);
  this.render();
}

Map.prototype.updatePosition = function(update){
  this.entities.forEach(function(entity){
    if (entity.id == update.id){
      entity.move(update.x*2,50);
    }
  })
}

map = new Map();

function firstConnection() {
   map.addEntity(new Entity(10,50,"mike" ));
}

function messageDispatch(m){
  console.log(m);
  map.updatePosition(m);
}

$(document).ready(function(){
      pubnub = PUBNUB.init({
         publish_key   : 'pub-c-c0f78210-168a-429f-bc4e-2fa1ee64b5c0',
         subscribe_key : 'sub-c-afbab9e2-2a1b-11e4-b5f4-02ee2ddab7fe'
     })

     pubnub.subscribe({
         channel : "baecon",
         message : messageDispatch,
         connect : firstConnection
     })

})
