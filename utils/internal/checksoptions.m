function options = checksoptions (options,data,T)
% It checks options that are necessary in order to preprocess the data,
% and options that are relative to the stochastic inference.
% Later on, checkoptions will deal with options more specifically

N = length(T);
if ~isfield(options,'K'), error('K was not specified'); end
if ~isfield(options,'order')
    options.order = 0;
    warning('order was not specified - it will be set to 0'); 
end

% data options
if ~isfield(options,'Fs'), options.Fs = 1; end
if ~isfield(options,'embeddedlags'), options.embeddedlags = 0; end
if ~isfield(options,'pca'), options.pca = 0; end
if ~isfield(options,'pca_spatial'), options.pca_spatial = 0; end
if ~isfield(options,'firsteigv'), options.firsteigv = 0; end
if ~isfield(options,'varimax'), options.varimax = 0; end
if ~isfield(options,'pcamar'), options.pcamar = 0; end
if ~isfield(options,'pcapred'), options.pcapred = 0; end
if ~isfield(options,'vcomp') && options.pcapred>0, options.vcomp = 1; end
if ~isfield(options,'onpower'), options.onpower = 0; end
if ~isfield(options,'leida'), options.leida = 0; end
if ~isfield(options,'filter'), options.filter = []; end
if ~isfield(options,'detrend'), options.detrend = 0; end
if ~isfield(options,'downsample'), options.downsample = 0; end
if ~isfield(options,'leakagecorr'), options.leakagecorr = 0; end
if ~isfield(options,'standardise'), options.standardise = 1; end %(options.pca>0);
if ~isfield(options,'standardise_pc'), options.standardise_pc = length(options.embeddedlags)>1; end 
if ~isfield(options,'crosstermsonly'), options.crosstermsonly = 0; end

if ~isfield(options,'grouping') || isempty(options.grouping)
    options.grouping = ones(length(T),1); 
elseif ~all(options.grouping==1)
    warning('grouping option is not yet implemented for stochastic learning')
    options.grouping = ones(length(T),1); 
else
    options.grouping = ones(length(T),1); 
end  

% Check integrity of preproc parameters
if ~isempty(options.filter)
    if length(options.filter)~=2, error('options.filter must contain 2 numbers of being empty'); end
    if (options.filter(1)==0 && isinf(options.filter(2)))
        warning('The specified filter does not do anything - Ignoring.')
        options.filter = [];
    elseif (options.filter(2) < options.Fs/2) && options.order >= 1
        warning(['The lowpass cutoff frequency is lower than the Nyquist frequency - ' ...
            'This is discouraged for a MAR model'])
    end
end
if options.downsample > 0 && isfield(data,'C')
    warning('The use of downsampling is currently not compatible with specifying data.C');
    data = rmfield(data,'C');
end
if options.downsample > options.Fs
   warning('Data is going to be upsampled') 
end
if options.leakagecorr ~= 0
    tmp = which('ROInets.closest_orthogonal_matrix');
    if isempty(tmp)
       error('For leakage correction, ROInets must be in path') 
    end
end
if options.leida
   if options.onpower
       error('Options leida and onpower are not compatible')
   end
   if options.order > 0
       error('Option leida and order > 0 are not compatible')
   end   
   if options.pca > 0
       error('Options leida and pca are not compatible')
   end
   if isfield(options,'covtype') && ...
           (strcmp(options.covtype,'full') || strcmp(options.covtype,'diag'))
       error('When using leida, covtype cannot be full or diag')
   end
   if length(options.embeddedlags) > 1
       error('Option leida and embeddedlags are not compatible')
   end
end

if isfield(options,'crosstermsonly') && options.crosstermsonly
    if isfield(options,'S') 
        warning('S will be ignored with crosstermonly=1'); 
    end
    if isfield(options,'order') && options.order~=0 
        warning('order (and all MAR parameters) will be ignored with crosstermonly=1'); 
    end
    if isfield(options,'zeromean') && options.zeromean~=1
        warning('zeromean will be ignored with crosstermonly=1'); 
    end
    if isfield(options,'embeddedlags') && length(options.embeddedlags)>1
        warning('embeddedlags will be ignored with crosstermonly=1'); 
    end    
    if isfield(options,'pca') && options.pca~=0
        warning('pca will be ignored with crosstermonly=1');  
    end
    if isfield(options,'covtype') && ~strcmp(options.covtype,'uniquediag')
        warning('covtype will be ignored with crosstermonly=1'); 
    end 
    options.crosstermsonly = 0;
    X = loadfile(data{1},T{1},options); ndim = size(X,2);
    options.crosstermsonly = 1;
    options.S = - ones(2*ndim);
    options.S(ndim+(1:ndim),1:ndim) = ones(ndim) - 2*eye(ndim);
    options.order = 1;  
    options.zeromean = 1; 
    options.embeddedlags = 0; 
    options.pca = 0;
    options.covtype = 'uniquediag';
end


if options.zeromean==0 && options.firsteigv
    error('firsteigv can only be used for zeromean=1')
end
if options.order > 1 && options.firsteigv
    error('firsteigv can only be used for order=0')
end
if options.pca>0 && options.firsteigv
    error('firsteigv and pca are not compatible')
end

if length(options.embeddedlags)==1 && options.pca_spatial>0
   warning('pca_spatial only applies when using embedded lags; use pca instead')
   options.pca_spatial = 0;
end

if size(options.grouping,1)==1,  options.grouping = options.grouping'; end

% Specific BigHMM options
if ~isfield(options,'BIGNinitbatch'), options.BIGNinitbatch = options.BIGNbatch; end
if ~isfield(options,'BIGprior'), options.BIGprior = []; end
if ~isfield(options,'BIGcyc'), options.BIGcyc = 200; end
if ~isfield(options,'BIGmincyc'), options.BIGmincyc = 10; end
if ~isfield(options,'BIGundertol_tostop'), options.BIGundertol_tostop = 5; end
if ~isfield(options,'BIGcycnobetter_tostop'), options.BIGcycnobetter_tostop = 20; end
if ~isfield(options,'BIGtol'), options.BIGtol = 1e-5; end
if ~isfield(options,'BIGinitrep'), options.BIGinitrep = 1; end
if ~isfield(options,'BIGforgetrate'), options.BIGforgetrate = 0.9; end
if ~isfield(options,'BIGdelay'), options.BIGdelay = 1; end
if ~isfield(options,'BIGbase_weights'), options.BIGbase_weights = 0.95; end % < 1 will promote democracy
if ~isfield(options,'BIGcomputeGamma'), options.BIGcomputeGamma = 1; end
if ~isfield(options,'BIGdecodeGamma'), options.BIGdecodeGamma = 1; end
if ~isfield(options,'BIGverbose'), options.BIGverbose = 1; end  
if ~isfield(options,'initial_hmm'), options.initial_hmm = []; end
options.BIGbase_weights = options.BIGbase_weights * ones(1,N);
if ~isfield(options,'Gamma'), options.Gamma = []; end
if ~isfield(options,'hmm'), options.hmm = []; end
if options.BIGdelay > 1, warning('BIGdelay is recommended to be 1.'); end

% MAR parameters
if ~isfield(options,'zeromean')
    if options.order>0, options.zeromean = 1; 
    else, options.zeromean = 0;
    end
end
if ~isfield(options,'covtype') && options.leida 
    options.covtype = 'uniquediag'; 
elseif ~isfield(options,'covtype') && (~isempty(S) || ...
        (isfield(options,'S') && ~isempty(options.S)) )
    options.covtype = 'diag'; 
elseif ~isfield(options,'covtype'), options.covtype = 'full'; 
end
if ~isfield(options,'orderoffset'), options.orderoffset = 0; end
if ~isfield(options,'timelag'), options.timelag = 1; end
if ~isfield(options,'exptimelag'), options.exptimelag = 0; end
if ~isfield(options,'cyc'), options.cyc = 15; end
if ~isfield(options,'initcyc'), options.initcyc = 5; end
if ~isfield(options,'initrep'), options.initrep = 3; end
if ~isfield(options,'inittype') 
    if options.initcyc>0 && options.initrep>0 
        options.inittype = 'hmmmar';
    else
        options.inittype = 'random';
    end
end
if ~isfield(options,'useParallel'), options.useParallel = 1; end
if ~isfield(options,'uniqueAR'), options.uniqueAR = 0; end

if ~strcmp(options.covtype,'full') && options.firsteigv
    error('firsteigv can only be used for covtype=full')
end

%if isfield(options,'S') && ~all(options.S(:)==1)
%    error('S(i,j)<1 is not yet implemented for stochastic inference')
%end

% Drop states? 
if ~isfield(options,'dropstates')
    options.dropstates = 0;
elseif options.droptstates==1
    warning('With stochastic learning, dropstates is set to 0')
    options.dropstates = 0;
end
    
options.verbose = 0; % shut up the individual hmmmar output
if options.order>0
    [options.orders,options.order] = formorders(options.order,options.orderoffset,options.timelag,options.exptimelag);
else
    options.orders = [];
end


end
