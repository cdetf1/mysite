# # from django.shortcuts import render
# from django.http import HttpResponse, HttpResponseRedirect
# # from django.template import loader
# # from django.http import Http404
# from django.shortcuts import render, get_object_or_404
# from django.urls import reverse

# from .models import Choice, Question

from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import get_object_or_404, render
from django.urls import reverse

from django.views import generic

from .models import Choice, Question

# Create your views here.

# def index(request):
#     # 1 return HttpResponse("Hello, world.")
    
#     # 2
#     # latest_question_list = Question.objects.order_by('-pub_date')[:5]
#     # output = ', '.join([q.question_text for q in latest_question_list])
#     # return HttpResponse(output)

#     # 3
#     # latest_question_list = Question.objects.order_by('-pub_date')[:5]
#     # template = loader.get_template('polls/index.html')
#     # context = {
#     #     'latest_question_list' : latest_question_list,
#     # }
#     # return HttpResponse(template.render(context, request))

#     # 4
#     latest_question_list = Question.objects.order_by('-pub_date')[:5]
#     context = {
#         'latest_question_list': latest_question_list,
#     }
#     return render(request, 'polls/index.html',context)
    
# def detail(request, question_id):

#     # 1
#     # return HttpResponse("You're looking at question %s." % question_id)
    
#     # 2 -> 404 오류 발생
#     # try:
#     #     question = Question.objects.get(pk=question_id)
#     # except Question.DoesNotExist:
#     #     raise Http404("Question does not exist")
#     # return render(request, 'polls/detail.html', {'question': question})

#     # 3
#     question = get_object_or_404(Question, pk=question_id)
#     return render(request, 'polls/detail.html', {'question': question}) 

# def results(request, question_id):
#     # response = "You're looking at the results of question %s."
#     return HttpResponse(response % question_id)

# 기존의 index, detail및 results 뷰를 제거하고 대신 Django의 일반 뷰를 사용하겠습니다.
class IndexView(generic.ListView):
    template_name = 'polls/index.html'
    context_object_name = 'latest_question_list'

    def get_queryset(self):
        """Return the last five published questions."""
        return Question.objects.order_by('-pub_date')[:5]


class DetailView(generic.DetailView):
    model = Question
    template_name = 'polls/detail.html'


class ResultsView(generic.DetailView):
    model = Question
    template_name = 'polls/results.html'

def vote(request, question_id):
    # 1
    # return HttpResponse("You're voting on question %s." % question_id)

    # 2
    question = get_object_or_404(Question, pk=question_id)
    try:
        selected_choice = question.choice_set.get(pk=request.POST['choice'])
    except (KeyError, Choice.DoesNotExist):
        # Redisplay the question voting form.
        return render(request, 'polls/detail.html', {
            'question': question,
            'error_message': "You didn't select a choice.",
        })
    else:
        selected_choice.votes += 1
        selected_choice.save()
        # Always return an HttpResponseRedirect after successfully dealing
        # with POST data. This prevents data from being posted twice if a
        # user hits the Back button.
        return HttpResponseRedirect(reverse('polls:results', args=(question.id,)))

    # # 3
    # if request.method == 'GET':
    #     do_somthing()
    # elif request.method == 'POST':
    #     question = get_object_or_404(Question, pk=question_id)
    #     try:
    #         selected_choice = question.choice_set.get(pk=request.POST['choice'])
    #     except (KeyError, choice.DoesNotExist):
    #         return render(request, 'polls/detail.html', {
    #             'question' : question,
    #             'error_message': "You didn't select a choice.",
    #         })     
    #     else:
    #         selected_choice.votes += 1
    #         selected_choice.save()
        
    #         return HttpResponseRedirect(reverse('polls:results', args=(question.id,)))