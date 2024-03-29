ad_page_contract {
    @author Mattia Righetti (mattia.righetti@professionefinanza.com)
    @creation-date Thursday 19 February 2015
} {
    esame_id:naturalnum
    redo:optional
}
set page_title "PFAwards - Test Online"
# Controllo su utenza
if {![ad_conn user_id]} {
    ad_return_complaint 1 "<strong>Utente non autorizzato</strong><br>Non hai le credenziali adatte per svolgere il test selezionato."
} else {
    set persona_id [db_string query "select persona_id from crm_persone where user_id = [ad_conn user_id]"]
}
set award_id [pf::awards::id]
#Capisce se esame è prima o seconda fase
if {[db_0or1row query "select * from awards_esami where esame_id = :esame_id and award_id = :award_id"]} {
    # Se esame precedentemente rifiutato, rigenera per una volta
     if {[info exists redo]} {
	 db_1row query "select categoria_id, scadenza from awards_esami where esame_id = :esame_id"
	 if {![db_0or1row query "select * from awards_esami where award_id = :award_id and categoria_id = :categoria_id and persona_id = :persona_id and stato = 'rifiutato'"]} {
	     db_dml query "update awards_esami set stato = 'rifiutato' where esame_id = :esame_id"
	     # Controlla precedenti bonus
	     if {[db_0or1row query "select * from awards_bonus where esame_id = :esame_id limit 1"]} {
		 set bonus_id [db_string query  "select bonus_id from awards_bonus where esame_id = :esame_id limit 1"]
	     } else {
		 set bonus_id ""
	     }
	     set esame_id [db_string query "select coalesce(max(esame_id)+trunc(random()*99+1), 1) from awards_esami"]
	     db_dml query "insert into awards_esami (esame_id, persona_id, categoria_id, attivato, award_id, data_iscr, decorrenza, scadenza) values (:esame_id, :persona_id, :categoria_id, true, :award_id, current_date, current_date, :scadenza)"
	    if {$bonus_id ne ""} {
		db_dml query "update awards_bonus set esame_id = :esame_id where bonus_id = :bonus_id"
	    }
	} else {
	    ad_return_complaint 1 "Risulta che hai già rifiutato l'esame una volta. Ti ricordiamo che non è possibile rifarlo più di una volta."
	}
    }
    if {![db_0or1row query "select * from awards_esami where persona_id = :persona_id and esame_id = :esame_id and end_time is null and attivato is true"]} {
	ad_return_warning "Nessun esame - PF Awards" "Non vi sono esami attivi per l'utenza."
    } else {
	with_catch errmsg {
	    #Controlla se l'esame è stato generato. Se no lo genera.
	    if {![db_0or1row query "select * from awards_rispusr where esame_id = :esame_id limit 1"]} {
		ns_log notice ExamID $esame_id not generated. Is about to be though.
		ad_returnredirect [export_vars -base "test-generator" {esame_id persona_id categoria_id}]
		ad_script_abort
	    }	
	    ad_set_cookie esame_id $esame_id
	} {
	    ad_return_complaint 1 "<b>Attenzione: non è stato possibile accedere ed attivare l'esame richiesto.</b>Stiamo gi&agrave; lavorando per risolvere il problema. Qualora si voglia sollecitare l'intervento, prego scrivere a <a href=\"mailto:webmaster@professionefinanza.com\">webmaster@professionefinanza.com</a> inoltrando ciò che segue.<br>L'errore riportato dal sistema è il seguente: <br><br><code>$errmsg</code>"
	}
    }
    set categoria [db_string query "select c.titolo from awards_categorie c, awards_esami e where e.esame_id = :esame_id and e.categoria_id = c.categoria_id" ]
    if {[db_0or1row query "select * from awards_bonus where esame_id = :esame_id limit 1"]} {
	set punti [db_string query "select punti from awards_bonus where esame_id = :esame_id limit 1"]
	set descrizione [db_string query "select descrizione from awards_bonus where esame_id = :esame_id limit 1"]
	set bonus_html "<div class=\"alert alert-success alert-dismissible\" role=\"alert\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Chiudi\"><span aria-hidden=\"true\">&times;</span></button><strong>BONUS</strong> Ti ricordiamo che usufruirai di $punti crediti aggiuntivi, causale: <i>$descrizione</i></div>"
    } else {
	set bonus_html ""
    }
     set start_button "<a href=\"sessione\" class=\"btn btn-lg btn-primary\"><span class=\"glyphicon glyphicon-play-circle\"></span> Inizia l'esame</a>"
     set advice_html "<div class=\"well\">La valutazione delle tue competenze in <b>$categoria</b> sta per cominciare.<br>Avrai a disposizione 15 minuti per svolgere il test di 15 domande, alcune classificate come facili (la singola risposta giusta ti darà 5 crediti mentre ogni sbagliata toglierà 2 crediti) altre come difficili (10 punti per la giusta e -4 per le sbagliate). Nel caso in cui non fossi soddisfatto del tuo risultato potrai ripetere IMMEDIATAMENTE il test UNA sola volta ATTENZIONE: una volta uscito dalla sessione non potrai ripetere il test.<br/>Il PDF con le risposte corrette sarà disponibile al termine della prima fase,dopo il 23 ottobre. Passeranno alla seconda fase di valutazione i migliori 30 partecipanti e comunque tutti coloro che otterranno più di 75 crediti. In bocca al lupo!</div></br>"   
 }
# Se esame seconda fase
if {[db_0or1row query "select * from awards_esami_2 where esame_id = :esame_id"]} {
    if {![db_0or1row query "select * from awards_esami_2 where persona_id = :persona_id and esame_id = :esame_id and end_time is null and attivato is true"]} {
        ad_return_warning "Nessun esame - PF Awards" "Non vi sono esami attivi per l'utenza."
    } else {
        with_catch errmsg {
            #Controlla se l'esame è stato generato. Se no lo genera.
	    if {![db_0or1row query "select * from awards_rispusr_2 where esame_id = :esame_id limit 1"]} {
		# Genera esame
		set categoria_id [db_string query "select categoria_id from awards_esami_2 e2 where e2.esame_id = :esame_id"]
		db_foreach query "select domanda_id from awards_domande_2 where categoria_id = :categoria_id and award_id = :award_id order by item_order" {
		    set rispusr_id [db_string query "select coalesce( max(rispusr_id) + trunc(random()*99+1), trunc( random()*99+1)) from awards_rispusr_2"]
		    db_dml query "insert into awards_rispusr_2 (rispusr_id, domanda_id, esame_id) values (:rispusr_id, :domanda_id, :esame_id)"
		}
	    }
	} {
            ad_return_complaint 1 "<b>Attenzione: non è stato possibile accedere ed attivare l'esame richiesto.</b>Stiamo gi&agrave; lavorando per risolvere il problema. Qualora si voglia sollecitare l'intervento, prego scrivere a <a href=\"mailto:webmaster@professionefinanza.com\">webmaster@professionefinanza.com</a> inoltrando ciò che segue.<br>L'errore riportato dal sistema è il seguente: <br><br><code>$errmsg</code>"
        }
    }
    ad_set_cookie esame_id $esame_id
    set categoria [db_string query "select c.titolo from awards_categorie c, awards_esami_2 e where e.esame_id = :esame_id and e.categoria_id = c.categoria_id" ]
    set bonus_html ""
    set start_button "<a href=\"sessione-seconda-fase\" class=\"btn btn-lg btn-primary\"><span class=\"glyphicon glyphicon-play-circle\"></span> Vai al questionario</a>"
    set advice_html "<div class=\"well\">Il questionario di <b>$categoria</b> sta per cominciare.<br>Il questionario consta di <b>2 domande</b>. Potrai leggere la prima domanda e decidere di rispondere in un secondo momento; ti ricordo che, una volta confermata la risposta, non potrai più modificarla.
Al secondo quesito invece, dovrai rispondere immediatamente, dato il limite temporale di 45 minuti, senza avere la possibilità di uscire dal portale per poi rientrarvi. In bocca al lupo!"
}
ad_return_template
