window.onload = function(e) {
    // $('#main').hide();
    var isShown = false;
    var lang = 'pl';

    window.addEventListener("message", (event) => {
        var item = event.data;
        if (item !== undefined) {
            switch(item.type) {
                case 'ON_STATE':
                    if(item.display === true) {
                        $('#main').show();
                        isShown = true;
                    } else {
                        $('#main').hide();
                        isShown = false;
                    }

                    break;
                case 'ON_UPDATE':
                    if(item.info !== undefined) {
                        var data = item.info;
                        if (data.attacker !== undefined) {
                            if (lang == 'eng') {
                                $('#attacker').text('Attacker: ' + data.attacker);
                            } else {
                                $('#attacker').text('Atakujący: ' + data.attacker);
                            }
                        }
                        if(data.owner !== undefined) {
                            if (lang == 'eng') {
                                $('#owner').text('Owner: ' + data.owner);
                            } else {
                                $('#owner').text('Posiadacz: ' + data.owner);
                            }
                        }

                        if(data.hp !== undefined && data.maxHp !== undefined) {
                            var percent = (data.hp / data.maxHp) * 100.0;
                            percent = percent.toFixed(2)
                            $('#percent').text(percent + '%');
                            $('.actual-hp-bar').css('width', percent + '%');
                        }
                        if(data.dmg !== undefined) {
                            if (lang == 'eng') {
                                $('#dmg').text('Damage: ' + data.dmg[0] + data.dmg[1] + '/s')
                            } else {
                                $('#dmg').text('Obrażenia: ' + data.dmg[0] + data.dmg[1] + '/s')
                            }
                        }
                    }
                    break;
                case 'SET_LANG':
                    if (item.lang !== undefined) {
                        lang = item.lang
                        
                        if (lang == 'pl') {
                            $('#top-text').text('ŻYCIE TERYTORIUM');
                        }
                    }

                    break;
                default:
                    break;
            }
        }
    })
}