$( document ).ready(function() {
  $('#help_menu').on('click', function() {
    ga('send', 'event', 'Support', 'Help Modal');
  });

  $('#view_tutorial').on('click', function() {
    ga('send', 'event', 'Support', 'Tutorial overlay');
  });

  $('#visit_support').on('click', function() {
    ga('send', 'event', 'Support', 'Support site');
  });
});

function tracking(type){
  switch(type){
    case 'chat':
      ga('send', 'event', 'Support', 'Account Manager', 'chat');
      break;
    case 'email':
      ga('send', 'event', 'Support', 'Account Manager', 'email');
      break;
  }
  }