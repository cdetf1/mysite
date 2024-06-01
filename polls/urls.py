from django.urls import path

from . import views

app_name = 'polls'
urlpatterns = [
    # # ex: /polls/
    # path('', views.index, name='index'),
    # # ex: /polls/5/
    # path('<int:question_id>/', views.detail, name='detail'),
    # # ex: /polls/5/results/
    # path('<int:question_id>/results/', views.results, name='results'),
    # # ex: /polls/5/vote/
    # path('<int:question_id>/vote/', views.vote, name='vote'),
    # # # the 'name' value as called by the {% url %} template tag
    # # path('<int:question_id>/', views.detail, name='detail'),
    # # added the word 'specifics'
    # path('specifics/<int:question_id>/', views.detail, name='detail'),
    

    # 두 번째 및 세 번째 패턴의 경로 문자열에서 일치하는 패턴의 이름이 에서 로 변경 <question_id>되었습니다 <pk>.
    path('', views.IndexView.as_view(), name='index'),
    path('<int:pk>/', views.DetailView.as_view(), name='detail'),
    path('<int:pk>/results/', views.ResultsView.as_view(), name='results'),
    path('<int:question_id>/vote/', views.vote, name='vote'),

]