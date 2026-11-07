import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
from collections import defaultdict

if __name__ == '__main__':
	start = False
	currentYear = None
	years = []
	pubs = defaultdict(list)
	title = ''
	names = ''
	venue = ''
	link = ''
	with open(os.path.join(ROOT, 'publication.html'), 'r') as f:
		for line in f:
			line = line.strip()
			
			if not line: continue
			
			if line == '<h2>Publications</h2>':
				start = True
			
			if line == '</section><!-- End Publication Section -->':
				start = False
			
			if not start: continue
			
			if line.startswith('<span>') and line.endswith('</span>'):
				currentYear = line[6:(len(line)-7)]
				years += [currentYear]
				continue
			
			if line.startswith('<li><b>'):
				if title: raise Exception('Title error: ' + line)
				title = line[7:line.index('</b>')].strip()
				continue
			
			if line.endswith('<br>') and not line.startswith('<li><b>'):
				if (not title): raise Exception('Name error: ' + line)
				if not names:
					names = line[0:line.index('<br>')].strip()
				else:
					if venue: raise Exception('Venue error: ' + line)
					venue = line[0:line.rindex('<br>')].strip()
				continue
				
			if line.startswith('[<a target=\"'):
				if link or (line.index('href') < 0) or (not venue) or (not names) or (not title): raise Exception('Link error: ' + line)
				line = line[(line.index('href')+6):]
				if line.startswith('\"'):
					link = ''
				else:
					link = line[0:line.index('\"')]
					if link.startswith('pubs'):
						link = link.replace('pubs', 'https://thienhuunguyen.github.io/pubs')
				
				pubs[currentYear] += [[title, names, venue, link]]
				#print(title, ', ', names, ', ', venue, ', ', link)
				title, names, venue, link = '', '', '', ''
				
				
	for y in pubs:
		print(y, ' num of pubs: ', len(pubs[y]))
	
	md = open(os.path.join(ROOT, 'tools', 'publications.md'), 'w')
	for y in years:
		md.write('### ' + y + '\n\n')
		
		for title, names, venue, link in pubs[y]:
			md.write('- **' + title + '**\n\n')
			md.write('\t' + names + '\n\n')
			md.write('\t' + venue.replace('<u><b>','**').replace('</b></u>','**') + '\n\n')
			if link:
				md.write('\t' + '[[PAPER]('+link+')]\n\n')
			else:
				md.write('\t' + '[[To Appear]('+link+')]\n\n')
	md.close()
		
			