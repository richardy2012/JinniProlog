% fixed in 5.10


bug(N):-
  findall(I-N,for(I,1,N),NNs),
bug(_):-