ad_page_contract {
    @author Mattia Righetti (mattia.righetti@professionefinanza.com)
} {
    esame_id:integer,optional
}
if {![info exists esame_id]} {
    set esame_id [ad_get_cookie esame_id]
}
if {[db_0or1row query "select * from awards_esami where esame_id = :esame_id and end_time is null"]} {
    db_dml query "update awards_esami set end_time = current_timestamp where esame_id = :esame_id"
}
set tempo [db_string query "select to_char(end_time - start_time, 'MI:SS') from awards_esami where esame_id = :esame_id"]
set punteggio 0
db_foreach query "select risposta_id from awards_rispusr where esame_id = :esame_id" {
    if {[db_0or1row query "select punti from awards_risposte where risposta_id = :risposta_id"]} {
	set punti [db_string query "select punti from awards_risposte where risposta_id = :risposta_id"]
	set punteggio [expr {$punteggio + $punti}]
    }
}
if {[db_0or1row query "select * from awards_bonus where esame_id = :esame_id limit 1"]} {
    set bonus [db_string query "select punti from awards_bonus where esame_id = :esame_id"]
    set punteggio [expr {$punteggio + $bonus}]
}
db_dml query "update awards_esami set punti = :punteggio where esame_id = :esame_id"
# Prepara PDF
set html "<html><table border=\"0\" width=\"100%\">"
# Imposta titolo testata
set title "Esame #"
append title $esame_id
# Imposta categoria e nome utente
set persona_id [db_string query "select persona_id from awards_esami where esame_id = :esame_id"]
set nominativo [db_string query "select nome||' '||cognome from crm_persone where persona_id = :persona_id"]
set categoria [db_string query "SELECT c.titolo FROM awards_categorie c, awards_esami e  WHERE e.categoria_id = c.categoria_id AND e.esame_id = :esame_id"]
append html "<tr><td colspan=\"1\" width=\"80%\"><center><font size=\"4em\" face=\"Helvetica\"><img src=\"http://images.professionefinanza.com/logos/pfawards.png\" height=\"30px\"></img><br><br>$title</font><br><font size=\"3em\" face=\"Helvetica\">Credenziali: $nominativo <small>(Codice persona: $persona_id)</small></font><br><font size=\"3em\" face=\"Helvetica\">Categoria: <u>$categoria</u></font></td>"
append html "<td><center><font face=\"Helvetica\" size=\"0.5em\"><b>Punteggio totale:</b></font><br><font face=\"Courier New\" size=\"18px\"><b>$punteggio</b></font></center></td></tr><tr><td colspan=\"2\"><br>&nbsp;<br></td></tr></table><table border=\"1\" cellpadding=\"5\" bordercolor=\"#cbcbcb\" width=\"100%\">"
# Ciclo di estrazione domande e risposte
set counter 1
db_foreach query "SELECT rispusr_id FROM awards_rispusr WHERE esame_id = :esame_id ORDER BY item_order" {
    # Estrae corpo della domanda
    set domanda_id [db_string query "SELECT domanda_id FROM awards_rispusr WHERE rispusr_id = :rispusr_id"]
    set domanda [db_string query "SELECT d.testo FROM awards_domande d, awards_rispusr r WHERE d.domanda_id = r.domanda_id AND r.rispusr_id = :rispusr_id"]
    append html "<tr><td bordercolor=\"#333333\"><center><big>$counter</big></center></td><td colspan=\"2\"><font face=\"Times New Roman\" size=\"3em\"><b>$domanda</b></font></td></tr>"
    # Estrae risposta data se vi è
    if {[db_0or1row query "SELECT risposta_id FROM awards_rispusr WHERE rispusr_id = :rispusr_id AND risposta_id IS NOT NULL"]} {
	set rispostadata_id [db_string query "SELECT risposta_id FROM awards_rispusr WHERE rispusr_id = :rispusr_id"]
	set risposta [db_string query "SELECT testo FROM awards_risposte WHERE risposta_id = :rispostadata_id"]
	# Controlla se la risposta data è giusta 
	set punti [db_string query "SELECT punti FROM awards_risposte WHERE risposta_id = :rispostadata_id"]
	if {$punti > 0} {
	    append html "<tr><td><center><img src=\"http://images.professionefinanza.com/icons/tic.png\" width=\"12px\"></img></center></td><td><font face=\"Times New Roman\">$risposta</font></td><td><center><big>$punti</big></center></td></tr>"
	} else {
	    append html "<tr><td><center><img src=\"http://images.professionefinanza.com/icons/delete.gif\" width=\"12px\"></img></center></td><td><font face=\"Times New Roman\">$risposta</font></td><td><center><big>$punti</big></center></tr>"
	}
	# Estrae le altre risposte
	db_foreach query "SELECT risposta_id FROM awards_risposte WHERE domanda_id = :domanda_id AND risposta_id <> :rispostadata_id ORDER BY RANDOM()" {
	    set risposta [db_string query "SELECT testo FROM awards_risposte WHERE risposta_id = :risposta_id"]
	    set punti [db_string query "SELECT punti FROM awards_risposte WHERE risposta_id = :risposta_id"]
	    if {$punti > 0} {
		append html "<tr><td><center><small>Giusta</small></center></td><td><font face=\"Times New Roman\">$risposta</font></td><td><center><small>($punti)</small></center></td></tr>"
	    } else {
		append html "<tr><td>&nbsp;</td><td><font face=\"Times New Roman\">$risposta</font></td><td>&nbsp;</td></tr>"
	    }
	}
    } else {
	# Nessuna risposta ergo estrae tutte le risposte
	db_foreach query "SELECT risposta_id FROM awards_risposte WHERE domanda_id = :domanda_id ORDER BY RANDOM()" {
            set risposta [db_string query "SELECT testo FROM awards_risposte WHERE risposta_id = :risposta_id"]
            set punti [db_string query "SELECT punti FROM awards_risposte WHERE risposta_id = :risposta_id"]
            if {$punti > 0} {
                append html "<tr><td><center><small>Giusta</small></center></td><td><font face=\"Times New Roman\">$risposta</td><td><center><small>($punti)</small><center></font></td></tr>"
            } else {
                append html "<tr><td>&nbsp;</td><td><font face=\"Times New Roman\">$risposta</font></td><td>&nbsp;</td></tr>"
            }
        }
    }
    incr counter
}
if {[db_0or1row query "select * from awards_bonus where esame_id = :esame_id limit 1"]} {
    set bonus [db_string query "select punti from awards_bonus where esame_id = :esame_id limit 1"]
    set descrizione [db_string query "select descrizione from awards_bonus where esame_id = :esame_id limit 1"]
    append html "<tr><td colspan=\"3\"><big><br>&nbsp;</br></big></td></tr><tr><td><center><small>BONUS</small></center></td><td>$descrizione</td><td><center>$bonus</center></td></tr>"
}
append html "</table>"
append html "</html>"
set filenamehtml "/usr/share/openacs/packages/pfawards/www/temporary.html"
set filenamepdf  "/usr/share/openacs/packages/pfawards/www/files/exams/exam_"
append filenamepdf $persona_id "_" $esame_id ".pdf"
set link "http://www.pfawards.it/files/exams/exam_"
append link $persona_id "_" $esame_id ".pdf"
set file_html [open $filenamehtml w]
puts $file_html $html
close $file_html
with_catch error_msg {
    exec htmldoc --portrait --webpage --header ... --footer ... --quiet --left 1cm --right 1cm --top 1cm --bottom 1cm --fontsize 12 -f $filenamepdf $filenamehtml
} {
    ns_log notice "errore htmldoc  <code>$error_msg </code>"
}
ns_unlink $filenamehtml
db_dml query "update awards_esami set stato = 'svolto', pdf_doc = '$link' where esame_id = :esame_id"
ad_set_cookie esame_id
ad_return_template
