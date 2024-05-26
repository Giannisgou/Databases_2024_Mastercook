-- Queries/ Exercise 3

-- 3.1 Μέσος Όρος Αξιολογήσεων (σκορ) ανά Μάγειρα και Εθνική Κουζίνα. 
-- Ανα Μάγειρα
SELECT chef_name, ROUND(AVG(total_score),2) AS average_score 
FROM chef_score
GROUP BY id;
-- Ανα Εθνική Κουζίνα. 
SELECT ro.rec_origin_name as recipe_origin, ROUND(AVG(total_score),2) AS average_score 
FROM origin_score AS os INNER JOIN rec_origin AS ro on os.id = ro.or_id
GROUP BY id;

-- 3.2 Για δεδομένη Εθνική κουζίνα και έτος, ποιοι μάγειρες ανήκουν σε αυτήν και ποιοι μάγειρες συμμετείχαν σε επεισόδια;
-- Ποιοί ανήκουν στην κουζίνα
SELECT CONCAT(c.chef_fname, " ", c.chef_lname) AS chef_name
FROM rec_origin AS r INNER JOIN chef_origin AS co ON co.or_id = r.or_id INNER JOIN chef AS c ON co.chef_id = c.chef_id 
WHERE r.rec_origin_name="Mexican";

-- Ποιοί συμμετείχαν σε επεισόδεια
SELECT CONCAT(c.chef_fname, " ", c.chef_lname) AS chef_name
FROM chef c
WHERE c.chef_id IN (SELECT cont.chef_id 
					FROM contestants AS cont INNER JOIN episodes AS e ON cont.ep_id = e.ep_id 
					WHERE e.season = 5 AND cont.rec_id IN (SELECT rec.rec_id 
															FROM recipe rec JOIN rec_origin recor ON rec.or_id = recor.or_id
															WHERE recor.rec_origin_name = 'American'));

-- 3.3 Βρείτε τους νέους μάγειρες (ηλικία < 30 ετών) που έχουν τις περισσότερες συνταγές.

SELECT CONCAT(c.chef_fname, " ", c.chef_lname) AS chef_name, chef_Dbirth, (YEAR(CURRENT_DATE()) - YEAR(c.chef_Dbirth)) AS chef_age, COUNT(DISTINCT cont.rec_id) AS number_of_recipes
FROM chef c INNER JOIN contestants cont ON c.chef_id = cont.chef_id
WHERE  (YEAR(CURRENT_DATE()) - YEAR(c.chef_Dbirth)) < 30
GROUP BY c.chef_id
ORDER BY number_of_recipes DESC;
/*Εάν θέλει συνολικές συνταγές που μπορεί (με βάση τις εθνικές κουζίνες στις οποίες εξειδικεύεται) να μαγειρέψει
SELECT CONCAT(c.chef_fname, " ", c.chef_lname) AS chef_name, chef_Dbirth, COUNT(r.rec_id) AS number_of_recipes
FROM chef c INNER JOIN chef_origin co ON c.chef_id = co.chef_id INNER JOIN recipe r ON r.or_id = co.or_id
WHERE (YEAR(CURRENT_DATE()) - YEAR(chef_Dbirth)) < 30
GROUP BY c.chef_id
ORDER BY number_of_recipes DESC;*/

-- 3.4 Βρείτε τους μάγειρες που δεν έχουν συμμετάσχει ποτέ σε ως κριτές σε κάποιο επεισόδιο.

SELECT CONCAT(chef_fname, " ", chef_lname) AS chef_name
FROM chef 
WHERE chef_id NOT IN (SELECT chef_id 
						FROM judge);

-- 3.5 Ποιοι κριτές έχουν συμμετάσχει στον ίδιο αριθμό επεισοδίων σε διάστημα ενός έτους με περισσότερες από 3 εμφανίσεις;
WITH chef_judge_occ AS (
SELECT c.chef_id AS chef_id, COUNT(*) AS judge_app
FROM judge j INNER JOIN chef c ON c.chef_id = j.chef_id INNER JOIN episodes e ON e.ep_id = j.ep_id
GROUP BY season, c.chef_id) 
SELECT cj1.chef_id, cj2.chef_id, cj1.judge_app
FROM chef_judge_occ cj1 INNER JOIN chef_judge_occ cj2 ON cj1.judge_app = cj2.judge_app AND cj1.chef_id < cj2.chef_id
WHERE cj1.judge_app >= 3
ORDER BY cj1.judge_app DESC;

-- 3.6 Πολλές συνταγές καλύπτουν περισσότερες από μια ετικέτες. Ανάμεσα σε ζεύγη πεδίων (π.χ. brunch και κρύο πιάτο) που είναι κοινά στις συνταγές, βρείτε τα 3 κορυφαία (top-3) 
-- ζεύγη που εμφανίστηκαν σε επεισόδια Για το ερώτημα αυτό η απάντηση σας θα πρέπει να περιλαμβάνει εκτός από το ερώτημα (query), εναλλακτικό Query Plan (πχ με force index), 
-- τα αντίστοιχα traces και τα συμπεράσματα σας από την μελέτη αυτών.

SELECT t1.tag_name, t2.tag_name, COUNT(*) as count
FROM recipe_tags rt1
JOIN recipe_tags rt2 ON rt1.rec_id = rt2.rec_id AND rt1.tag_id < rt2.tag_id
JOIN tags t1 ON rt1.tag_id = t1.tag_id
JOIN tags t2 ON rt2.tag_id = t2.tag_id
GROUP BY t1.tag_name, t2.tag_name
ORDER BY count DESC
LIMIT 3;

-- Force index

SELECT t1.tag_name, t2.tag_name, COUNT(*) as count
FROM recipe_tags rt1 FORCE INDEX (idx_rec_tags_rec_id)
JOIN recipe_tags rt2 FORCE INDEX (idx_rec_tags_rec_id) ON rt1.rec_id = rt2.rec_id AND rt1.tag_id < rt2.tag_id
JOIN tags t1 ON rt1.tag_id = t1.tag_id
JOIN tags t2 ON rt2.tag_id = t2.tag_id
GROUP BY  t1.tag_name, t2.tag_name
ORDER BY count DESC
LIMIT 3;

-- 3.7 Βρείτε όλους τους μάγειρες που συμμετείχαν τουλάχιστον 5 λιγότερες φορές από τον μάγειρα με τις περισσότερες συμμετοχές σε επεισόδια.

SELECT chef_name AS 'Chef Name', number_of_participations AS 'Number of Participations'
FROM participations
WHERE number_of_participations <= ((SELECT MAX(number_of_participations) FROM participations) -5)
ORDER BY number_of_participations; 

-- 3.8 Σε ποιο επεισόδιο χρησιμοποιήθηκαν τα περισσότερα εξαρτήματα (εξοπλισμός); Ομοίως με ερώτημα 3.6, η απάντηση σας θα πρέπει να περιλαμβάνει εκτός από το ερώτημα (query), 
-- εναλλακτικό Query Plan (πχ με force index), τα αντίστοιχα traces και τα συμπεράσματα σας από την μελέτη αυτών.

SELECT e.ep_id, e.season AS Season, e.ep_num AS Episode, COUNT(eq.equip_id) AS Episode_equipment
FROM contestants cont JOIN episodes e ON cont.ep_id = e.ep_id JOIN recipe r ON cont.rec_id = r.rec_id JOIN recipe_equipment eq ON r.rec_id = eq.rec_id
GROUP BY e.ep_id
ORDER BY Episode_equipment DESC
LIMIT 1;

-- Force index

-- 3.9 Λίστα με μέσο όρο αριθμού γραμμάριων υδατανθράκων στο διαγωνισμό ανά έτος

SELECT e.season AS Season, AVG(nutr.Carbohydrates_per_portion_gr * r.portions) AS 'Avg gramms of Carbohydrates per season'
FROM recipe_nutr_value AS nutr INNER JOIN recipe AS r ON r.rec_name = nutr.Recipe INNER JOIN contestants AS cont ON cont.rec_id = r.rec_id INNER JOIN episodes AS e on cont.ep_id = e.ep_id
GROUP BY season;

-- 3.10 Ποιες Εθνικές κουζίνες έχουν τον ίδιο αριθμό συμμετοχών σε διαγωνισμούς, σε διάστημα δύο συνεχόμενων ετών, με τουλάχιστον 3 συμμετοχές ετησίως

WITH origin_per_season AS ( SELECT ro.rec_origin_name AS Origin, e.season, COUNT(*) AS origin_app
							FROM episodes e 
							INNER JOIN episode_rec_origin ero ON e.ep_id = ero.ep_id 
							INNER JOIN rec_origin ro ON ero.or_id = ro.or_id
							GROUP BY ro.rec_origin_name, e.season),
consecutive_seasons AS (	SELECT o1.Origin, o1.season AS Season1, o2.season AS Season2, o1.origin_app AS origin_app_season1, o2.origin_app AS origin_app_season2, o1.origin_app + o2.origin_app AS total_app
							FROM origin_per_season o1
							INNER JOIN origin_per_season o2 ON o1.Origin = o2.Origin AND o1.season = o2.season - 1
							WHERE o1.origin_app >= 3 AND o2.origin_app >= 3)

SELECT DISTINCT cs1.Origin AS Origin1, cs2.Origin AS Origin2, cs1.total_app
FROM consecutive_seasons cs1 INNER JOIN consecutive_seasons cs2 ON cs1.total_app = cs2.total_app AND cs1.Origin < cs2.Origin
ORDER BY cs1.total_app DESC;

-- 3.11 Βρείτε τους top-5 κριτές που έχουν δώσει συνολικά την υψηλότερη βαθμολόγηση σε ένα μάγειρα. (όνομα κριτή, όνομα μάγειρα και συνολικό σκορ βαθμολόγησης)
WITH judgechef AS(
SELECT j.chef_id AS Judge, cont.chef_id AS Contestant, SUM(s.score) AS Total_Score
FROM contestants cont INNER JOIN score s ON s.cont_id = cont.cont_id INNER JOIN judge j ON j.jud_id = s.jud_id
GROUP BY j.chef_id, cont.chef_id
)
SELECT CONCAT(c1.chef_fname, " ", c1.chef_lname) AS Judge_name, CONCAT(c2.chef_fname, " ", c2.chef_lname) AS Contestant_name, Total_Score
FROM judgechef jc INNER JOIN chef c1 ON jc.Judge = c1.chef_id INNER JOIN chef c2 ON jc.Contestant = c2.chef_id
ORDER BY Total_score DESC
LIMIT 5;


-- 3.12 Ποιο ήταν το πιο τεχνικά δύσκολο, από πλευράς συνταγών, επεισόδιο του διαγωνισμού ανά έτος;

WITH MaxDiffPerSeason AS (SELECT season, MAX(total_ep_diff) AS max_diff
						FROM total_ep_difficulty
                        GROUP BY season)
SELECT t.season, e.ep_num AS episode, t.total_ep_diff AS max_diff
FROM total_ep_difficulty t INNER JOIN MaxDiffPerSeason m ON t.season = m.season AND t.total_ep_diff = m.max_diff INNER JOIN episodes e ON e.ep_id = t.ep_id;

-- 3.13 Ποιο επεισόδιο συγκέντρωσε τον χαμηλότερο βαθμό επαγγελματικής κατάρτισης (κριτές και μάγειρες);

SELECT e.ep_num, e.season, SUM(total) AS Exp_Level
FROM
((SELECT SUM(FIELD(chef_expertise, 'C Chef', 'B Chef', 'A Chef', 'Assistant Head Chef', 'Head Chef')) AS total, cont.ep_id
FROM contestants cont INNER JOIN chef c ON cont.chef_id = c.chef_id
GROUP BY cont.ep_id)
UNION
(SELECT SUM(FIELD(chef_expertise, 'C Chef', 'B Chef', 'A Chef', 'Assistant Head Chef', 'Head Chef')) AS total, j.ep_id
FROM judge j INNER JOIN chef c ON j.chef_id = c.chef_id
GROUP BY j.ep_id)) AS tot_exp_per_ep INNER JOIN episodes e ON tot_exp_per_ep.ep_id = e.ep_id
GROUP BY e.ep_id
ORDER BY Exp_Level
LIMIT 1;	-- To get only one

-- 3.14 Ποια θεματική ενότητα έχει εμφανιστεί τις περισσότερες φορές στο διαγωνισμό;

SELECT t.category, COUNT(t.theme_id) AS number_of_appearances
FROM contestants cont INNER JOIN recipe r ON cont.rec_id = r.rec_id INNER JOIN recipe_theme rt ON r.rec_id = rt.rec_id INNER JOIN theme t ON t.theme_id = rt.theme_id
GROUP BY t.theme_id
ORDER BY number_of_appearances DESC
LIMIT 1;

-- 3.15 Ποιες ομάδες τροφίμων δεν έχουν εμφανιστεί ποτέ στον διαγωνισμό;

SELECT fgroup_name
FROM food_group
WHERE fgroup_name NOT IN(SELECT fgroup_name
						FROM rec_group);