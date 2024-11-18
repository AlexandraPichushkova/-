
select year, month, day, userid, ts, devicetype, deviceid, query, next_query,
	case when (next_query is null) then 1
		 when ((next_ts - ts)::numeric/60 > 1) and next_length='next_short' then 2
		 when (next_ts - ts)::numeric/60 > 3 then 1
		 else 0                                             --по кол-ву минут между запросами определяю категорию is_final
		 end as is_final
	from(
	select year, month, day, userid, ts, devicetype, deviceid, query, next_query, next_ts,
		case when (length(next_query) > length(query)) then 'next_long'
		     when (length(next_query) <= length(query)) then 'next_short'
		end as next_length          --определяю является ли следующий запрос пользователя более или менее коротким
	from(
		select year, month, day, userid, ts, devicetype, deviceid,  query, 
			lead(ts) over (partition by userid order by ts) as next_ts,         --время следующего запроса пользователя
			lead(query) over (partition by userid order by ts) as next_query    --следующий запрос пользователя
		from query
		)
	)